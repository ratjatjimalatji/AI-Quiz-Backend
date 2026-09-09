# AI Quiz Backend API Specification

This document details all API endpoints and WebSocket channels available in the **AI Quiz Ruby Backend** (`AI-Quiz-Ruby`) as of the latest version of `develop`. It covers endpoint sections, HTTP methods, route paths, required parameters/headers, authentication mechanisms, response payloads, and real-time ActionCable events.

---

## Table of Contents
1. [Authentication & Headers](#authentication--headers)
2. [Health Check / System](#1-health-check--system)
3. [Hosts Section](#2-hosts-section)
4. [Games Section](#3-games-section)
5. [Players Section](#4-players-section)
6. [Submissions Section](#5-submissions-section)
7. [Rounds Section](#6-rounds-section)
8. [Questions Section](#7-questions-section)
9. [Real-Time WebSockets (ActionCable)](#8-real-time-websockets-actioncable)

---

## Authentication & Headers

Protected endpoints require a **Bearer Token** sent in the HTTP `Authorization` header.

### Host Authentication (`authenticate_host!`)
Used for host operations such as creating games (`POST /hosts/:id/create_game`), advancing game state (`POST /games/:id/advance_step`), and creating questions (`POST /questions`).

* **Header Name**: `Authorization`
* **Format**: `Bearer <HOST_TOKEN>`
* **Unauthorized Response (401)**:
  ```json
  {
    "error": "You are not authorized to perform this action."
  }
  ```
* **Forbidden Response (403)**:
  ```json
  {
    "error": "You do not have permission to access this resource."
  }
  ```

### Player Authentication (`authenticate_player!`)
Used for player operations such as submitting answers (`POST /submissions`).

* **Header Name**: `Authorization`
* **Format**: `Bearer <PLAYER_TOKEN>`
* **Unauthorized Response (401)**:
  ```json
  {
    "error": "You are not authorized to perform this action."
  }
  ```

---

## 1. Health Check / System

### Check Server Health
* **Section**: System Health
* **Endpoint**: `GET /up`
* **Auth Required**: No
* **Description**: Used by load balancers or uptime monitors to check if the Rails application is live.
* **Success Response (200 OK)**:
  * Status `200 OK` (HTML or empty response).

---

## 2. Hosts Section

### List All Hosts
* **Section**: Host Management
* **Endpoint**: `GET /hosts`
* **Auth Required**: No
* **Description**: Returns a list of all host records in the database.
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 1,
      "name": "Quiz Master Alex",
      "token": "4f9d0e1a-8c2b-4e12-b13c-7a9e0f31c25a",
      "created_at": "2026-09-08T10:00:00.000Z",
      "updated_at": "2026-09-08T10:00:00.000Z"
    }
  ]
  ```

### Register / Create Host
* **Section**: Host Management & Auth
* **Endpoint**: `POST /hosts`
* **Auth Required**: No
* **Description**: Registers a new host and generates a unique authentication token (`token`).
* **Request Body**:
  ```json
  {
    "host": {
      "name": "Quiz Master Alex"
    }
  }
  ```
* **Success Response (201 Created)**:
  ```json
  {
    "id": 1,
    "token": "4f9d0e1a-8c2b-4e12-b13c-7a9e0f31c25a"
  }
  ```

### Host Creates a Game
* **Section**: Host Management / Game Creation
* **Endpoint**: `POST /hosts/:id/create_game`
* **Auth Required**: Yes (`Bearer <HOST_TOKEN>`)
* **Description**: Authenticated host creates a new game session associated with their host ID. Automatically populates game quiz data/rounds, generates a unique 6-character uppercase hex `game_code`, and broadcasts `game_created` and `host_joined` events via ActionCable to stream `game_room_<game_code>`.
* **Path Parameters**:
  * `id`: Host ID
* **Success Response (201 Created)**:
  ```json
  {
    "id": 10,
    "code": "A3F8B2"
  }
  ```

---

## 3. Games Section

### List All Games
* **Section**: Game Management
* **Endpoint**: `GET /games`
* **Auth Required**: No
* **Description**: Retrieves all games in the system.
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 10,
      "game_code": "A3F8B2",
      "host_id": 1,
      "player_limit": 8,
      "status": "waiting",
      "current_round_id": null,
      "current_question_id": null,
      "question_started_at": null,
      "created_at": "2026-09-08T10:05:00.000Z",
      "updated_at": "2026-09-08T10:05:00.000Z"
    }
  ]
  ```

### Join Game / Create Player
* **Section**: Game Management / Player Lobby
* **Endpoint**: `POST /games/create_player`
* **Auth Required**: No
* **Description**: Joins a new player to the game matching `game_code`. Checks player limit (default limit is 8). On success, generates a player `token` and broadcasts a `player_joined` event via ActionCable.
* **Request Body / Parameters**:
  ```json
  {
    "game_code": "A3F8B2",
    "player": {
      "username": "PlayerOne"
    }
  }
  ```
* **Success Response (201 Created)**:
  ```json
  {
    "id": 5,
    "username": "PlayerOne",
    "score": 0,
    "eliminated": false,
    "game_id": 10,
    "token": "7b8a9c0d1e2f3a4b...",
    "created_at": "2026-09-08T10:06:00.000Z",
    "updated_at": "2026-09-08T10:06:00.000Z"
  }
  ```
* **Error Response (400 Bad Request - Missing Game Code)**:
  ```json
  {
    "error": "game_code is required"
  }
  ```
* **Error Response (422 Unprocessable Entity - Player Limit Exceeded)**:
  ```json
  {
    "error": "has reached the maximum number of players"
  }
  ```
* **Error Response (422 Unprocessable Entity - Validation Error)**:
  ```json
  {
    "username": [
      "is required"
    ]
  }
  ```

### Advance Game Step
* **Section**: Game Control
* **Endpoint**: `POST /games/:id/advance_step`
* **Auth Required**: Yes (`Bearer <HOST_TOKEN>`)
* **Description**: Advances the game state for the host's game (starts game, advances to next question/round, or marks game as completed). Updates `current_round_id`, `current_question_id`, sets `question_started_at`, and updates the question's `shown_at` timestamp.
* **Path Parameters**:
  * `id`: Game ID
* **Success Response (200 OK)**:
  ```json
  {
    "game_id": 10,
    "status": "in_progress",
    "current_round_id": 1,
    "current_question": {
      "id": 1,
      "title": "What is the capital of France?",
      "question_type": "multiple_choice",
      "position": 1,
      "round_id": 1,
      "shown_at": "2026-09-08T14:00:00.000Z",
      "options": [
        { "id": 1, "text": "London", "position": 1 },
        { "id": 2, "text": "Paris", "position": 2 }
      ]
    },
    "question_started_at": "2026-09-08T14:00:00.000Z"
  }
  ```
* **Error Response (422 Unprocessable Entity)**:
  ```json
  {
    "error": "Unable to advance game state"
  }
  ```

### Get Players for a Game
* **Section**: Game Management / Lobby Info
* **Endpoint**: `GET /games/get_players`
* **Auth Required**: No
* **Description**: Returns all players for a specific game by `game_code` (returning `id` and `username`).
* **Query Parameters**:
  * `game_code`: Game Code (e.g. `A3F8B2`)
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 5,
      "username": "PlayerOne"
    },
    {
      "id": 6,
      "username": "PlayerTwo"
    }
  ]
  ```

---

## 4. Players Section

### List All Players
* **Section**: Player Management
* **Endpoint**: `GET /players`
* **Auth Required**: No
* **Description**: Lists all players across all games.
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 5,
      "username": "PlayerOne",
      "score": 100,
      "eliminated": false,
      "game_id": 10,
      "token": "7b8a9c0d1e2f3a4b...",
      "created_at": "2026-09-08T10:06:00.000Z",
      "updated_at": "2026-09-08T10:06:00.000Z"
    }
  ]
  ```

### Get Player Details
* **Section**: Player Management
* **Endpoint**: `GET /players/:id`
* **Auth Required**: No
* **Description**: Returns details for a specific player by ID.
* **Path Parameters**:
  * `id`: Player ID
* **Success Response (200 OK)**:
  ```json
  {
    "id": 5,
    "username": "PlayerOne",
    "score": 100,
    "eliminated": false,
    "game_id": 10,
    "token": "7b8a9c0d1e2f3a4b...",
    "created_at": "2026-09-08T10:06:00.000Z",
    "updated_at": "2026-09-08T10:06:00.000Z"
  }
  ```

---

## 5. Submissions Section

### Submit Answer
* **Section**: Gameplay / Submissions
* **Endpoint**: `POST /submissions`
* **Auth Required**: Yes (`Bearer <PLAYER_TOKEN>`)
* **Description**: Submits an answer for the current question. Calculates response time based on `game.question_started_at`, verifies if the selected option position is correct, calculates and updates player points (`ScoreCalculator` & `ScoreUpdater`), and records the submission.
* **Request Body**:
  ```json
  {
    "submission": {
      "question_id": 1,
      "option_id": 2
    }
  }
  ```
* **Scoring Rules**:
  * Correct answer: Base score is `100` points.
  * Free time: `5,000 ms` (5 seconds).
  * Deduction: `-1 point` per second elapsed after free time.
  * Minimum score for correct answer: `75` points.
  * Incorrect answer: `0` points.
* **Success Response (201 Created)**:
  ```json
  {
    "submission": {
      "id": 1,
      "player_id": 5,
      "question_id": 1,
      "round_id": 1,
      "option_id": 2,
      "response_time_ms": 3200,
      "points_awarded": 100,
      "created_at": "2026-09-08T14:05:00.000Z",
      "updated_at": "2026-09-08T14:05:00.000Z"
    },
    "correct": true,
    "points_awarded": 100
  }
  ```
* **Error Response (401 Unauthorized)**:
  ```json
  {
    "error": "You are not authorized to perform this action."
  }
  ```

---

## 6. Rounds Section

### List All Rounds
* **Section**: Quiz / Round Management
* **Endpoint**: `GET /rounds`
* **Auth Required**: No
* **Description**: Retrieves all rounds, including nested questions and options. `correct_answer_ids` are omitted from questions in response output.
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 1,
      "title": "General Knowledge",
      "game_id": 10,
      "created_at": "2026-09-08T10:10:00.000Z",
      "updated_at": "2026-09-08T10:10:00.000Z",
      "questions": [
        {
          "id": 1,
          "title": "What is the capital of France?",
          "question_type": "multiple_choice",
          "position": 1,
          "round_id": 1,
          "created_at": "2026-09-08T10:10:00.000Z",
          "updated_at": "2026-09-08T10:10:00.000Z",
          "options": [
            { "id": 1, "text": "London", "position": 1, "question_id": 1 },
            { "id": 2, "text": "Paris", "position": 2, "question_id": 1 }
          ]
        }
      ]
    }
  ]
  ```

### Get Round Details
* **Section**: Quiz / Round Management
* **Endpoint**: `GET /rounds/:id`
* **Auth Required**: No
* **Description**: Retrieves details for a specific round including nested questions and options (omitting `correct_answer_ids`).
* **Path Parameters**:
  * `id`: Round ID
* **Success Response (200 OK)**:
  ```json
  {
    "id": 1,
    "title": "General Knowledge",
    "game_id": 10,
    "created_at": "2026-09-08T10:10:00.000Z",
    "updated_at": "2026-09-08T10:10:00.000Z",
    "questions": [
      {
        "id": 1,
        "title": "What is the capital of France?",
        "question_type": "multiple_choice",
        "position": 1,
        "round_id": 1,
        "options": [
          { "id": 1, "text": "London", "position": 1 },
          { "id": 2, "text": "Paris", "position": 2 }
        ]
      }
    ]
  }
  ```

### Create a Round
* **Section**: Quiz / Round Management
* **Endpoint**: `POST /rounds`
* **Auth Required**: No
* **Description**: Creates a round with optional nested questions and options.
* **Request Body**:
  ```json
  {
    "round": {
      "title": "Round 1 - Trivia",
      "game_id": 10,
      "questions_attributes": [
        {
          "title": "What is 2 + 2?",
          "question_type": 2,
          "correct_answer_ids": [1],
          "options_attributes": [
            { "text": "4", "position": 1 },
            { "text": "5", "position": 2 }
          ]
        }
      ]
    }
  }
  ```
* **Success Response (201 Created)**:
  ```json
  {
    "id": 1,
    "title": "Round 1 - Trivia",
    "game_id": 10,
    "created_at": "2026-09-08T10:10:00.000Z",
    "updated_at": "2026-09-08T10:10:00.000Z"
  }
  ```
* **Error Response (422 Unprocessable Entity)**:
  ```json
  {
    "errors": [
      "Title can't be blank"
    ]
  }
  ```

---

## 7. Questions Section

### Question Types (Enum Values)
* `0`: `true_false`
* `1`: `single_choice`
* `2`: `multiple_choice`
* `3`: `drag_drop_order`

### List All Questions
* **Section**: Question & Options Management
* **Endpoint**: `GET /questions`
* **Auth Required**: No
* **Description**: Fetches all questions (includes `options`, excludes `correct_answer_ids`).
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 1,
      "title": "What is 2 + 2?",
      "question_type": "multiple_choice",
      "position": 1,
      "round_id": 1,
      "options": [
        { "id": 1, "text": "4", "position": 1 }
      ]
    }
  ]
  ```

### Get Question Details
* **Section**: Question & Options Management
* **Endpoint**: `GET /questions/:id`
* **Auth Required**: No
* **Path Parameters**:
  * `id`: Question ID
* **Success Response (200 OK)**:
  ```json
  {
    "id": 1,
    "title": "What is 2 + 2?",
    "question_type": "multiple_choice",
    "position": 1,
    "round_id": 1,
    "options": [
      { "id": 1, "text": "4", "position": 1 }
    ]
  }
  ```

### Create Question
* **Section**: Question & Options Management
* **Endpoint**: `POST /questions`
* **Auth Required**: Yes (`Bearer <HOST_TOKEN>`)
* **Description**: Creates a new question within a round along with options.
* **Request Body**:
  ```json
  {
    "question": {
      "title": "Which planet is known as the Red Planet?",
      "question_type": "multiple_choice",
      "round_id": 1,
      "position": 1,
      "correct_answer_ids": [2],
      "options_attributes": [
        { "text": "Venus", "position": 1 },
        { "text": "Mars", "position": 2 }
      ]
    }
  }
  ```
* **Success Response (201 Created)**:
  ```json
  {
    "id": 2,
    "title": "Which planet is known as the Red Planet?",
    "question_type": "multiple_choice",
    "position": 1,
    "round_id": 1,
    "options": [
      { "id": 1, "text": "Venus", "position": 1 },
      { "id": 2, "text": "Mars", "position": 2 }
    ]
  }
  ```
* **Error Response (422 Unprocessable Entity)**:
  ```json
  {
    "errors": [
      "Title can't be blank"
    ]
  }
  ```

### Update Question
* **Section**: Question & Options Management
* **Endpoint**: `PATCH /questions/:id` / `PUT /questions/:id`
* **Auth Required**: No
* **Description**: Updates an existing question and its nested options. Returns question along with included options.
* **Path Parameters**:
  * `id`: Question ID
* **Request Body**:
  ```json
  {
    "question": {
      "title": "Updated Question Title",
      "options_attributes": [
        { "id": 1, "text": "New Option Text", "position": 1 }
      ]
    }
  }
  ```
* **Success Response (200 OK)**:
  ```json
  {
    "id": 1,
    "title": "Updated Question Title",
    "question_type": "multiple_choice",
    "position": 1,
    "round_id": 1,
    "correct_answer_ids": [1],
    "options": [
      {
        "id": 1,
        "text": "New Option Text",
        "position": 1,
        "question_id": 1
      }
    ]
  }
  ```
* **Error Response (422 Unprocessable Entity)**:
  ```json
  {
    "errors": [
      "Title can't be blank"
    ]
  }
  ```

---

## 8. Real-Time WebSockets (ActionCable)

### Connection URL & Authentication
* **WebSocket Path**: `/cable` (e.g. `ws://localhost:3000/cable`)
* **Connection Authentication**:
  * Token passed via query parameter `?token=<TOKEN>` OR HTTP Header `token: <TOKEN>`.
  * If token matches a valid `Host`, connects socket as `current_host`.
  * If token matches a valid `Player`, connects socket as `current_player`.
  * Unauthenticated connections are rejected.

### Channel: `GameChannel`
* **Subscription Params**:
  * `game_code`: The unique code of the game (e.g., `"A3F8B2"`).
* **Subscription Authorization**:
  * If connected as `current_player`, subscription is authorized only if player belongs to the game.
  * If connected as `current_host`, subscription is authorized only if host owns (`host_id`) the game.
* **Stream Name**: `game_room_<game_code>`

#### 1. Incoming Socket Action: `submit_answer`
* **Client Action**: Send command `submit_answer` to `GameChannel`.
* **Payload**:
  ```json
  {
    "command": "message",
    "identifier": "{\"channel\":\"GameChannel\",\"game_code\":\"A3F8B2\"}",
    "data": "{\"action\":\"submit_answer\",\"player_id\":5}"
  }
  ```
* **Broadcast Sent to Stream (`game_room_<game_code>`)**:
  ```json
  {
    "event": "answer_submitted",
    "player_id": 5,
    "status": "waiting_for_results"
  }
  ```

#### 2. Server Broadcast Events

* **`game_created`** (Triggered when host calls `POST /hosts/:id/create_game`):
  ```json
  {
    "event": "game_created",
    "game_code": "A3F8B2",
    "total_players": 0
  }
  ```

* **`host_joined`** (Triggered when host calls `POST /hosts/:id/create_game`):
  ```json
  {
    "event": "host_joined",
    "host": {
      "id": 1,
      "name": "Quiz Master Alex"
    }
  }
  ```

* **`player_joined`** (Triggered when player calls `POST /games/create_player`):
  ```json
  {
    "event": "player_joined",
    "player": {
      "id": 5,
      "username": "PlayerOne"
    },
    "total_players": 1,
    "player_limit": 8
  }
  ```

* **`answer_submitted`** (Triggered via `submit_answer` socket action):
  ```json
  {
    "event": "answer_submitted",
    "player_id": 5,
    "status": "waiting_for_results"
  }
  ```

* **`players_eliminated`** (Triggered via `PlayerEliminationService` after round end):
  ```json
  {
    "event": "players_eliminated",
    "round_id": 1,
    "round_title": "Round 1 - General Knowledge",
    "advancing_player_ids": [5, 6],
    "eliminated_players": [
      {
        "id": 7,
        "username": "PlayerThree",
        "final_score": 0
      }
    ]
  }
  ```

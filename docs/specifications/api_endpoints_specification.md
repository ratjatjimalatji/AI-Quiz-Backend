# AI Quiz Backend API Specification

This document details all API endpoints and WebSocket channels available in the **AI Quiz Ruby Backend** (`AI-Quiz-Ruby`) as of the latest version of `main`. It covers endpoint sections, HTTP methods, route paths, required parameters and headers, authentication mechanisms, scoring algorithms, power-up systems, tournament elimination rules, response payloads, and real-time ActionCable events.

---

## Table of Contents
1. [Architecture & Technology Stack](#architecture--technology-stack)
2. [Authentication & Headers](#authentication--headers)
3. [Health Check / System](#1-health-check--system)
4. [Hosts Section](#2-hosts-section)
5. [Games Section](#3-games-section)
6. [Players Section](#4-players-section)
7. [Submissions Section](#5-submissions-section)
8. [Power-Ups Section](#6-power-ups-section)
9. [Rounds Section](#7-rounds-section)
10. [Questions & Options Section](#8-questions--options-section)
11. [Tournament Progression & Knockout Elimination](#9-tournament-progression--knockout-elimination)
12. [Real-Time WebSockets (ActionCable)](#10-real-time-websockets-actioncable)

---

## Architecture & Technology Stack

* **Backend Framework**: Ruby on Rails 8.1 (API Mode)
* **Language**: Ruby 4.0+
* **Database**: PostgreSQL (with JSONB support and native string array columns)
* **Real-Time Communication**: ActionCable WebSockets over `/cable`
* **Media & File Attachments**: Active Storage (supporting image attachments on question options)
* **Concurrency & Background Operations**: SolidCable / SolidQueue

---

## Authentication & Headers

Protected endpoints and ActionCable channels require a token passed via standard HTTP headers.

### 1. Host Authentication (`authenticate_host!`)
Used for host-controlled operations such as creating games (`POST /hosts/:id/create_game`), advancing the game state (`POST /games/:id/advance_step`), authoring questions (`POST /questions`), and host rejoin (`POST /hosts/rejoin`).

* **Header Name**: `Authorization`
* **Format**: `Bearer <HOST_TOKEN>`
* **Unauthorized Response (401 Unauthorized)**:
  ```json
  {
    "error": "You are not authorized to perform this action."
  }
  ```
* **Forbidden Response (403 Forbidden)**:
  ```json
  {
    "error": "You do not have permission to access this resource."
  }
  ```

### 2. Player Authentication (`authenticate_player!`)
Used for player operations including answer submissions (`POST /submissions`), using power-ups (`POST /power_ups/use`), and player rejoin (`POST /players/rejoin`).

* **Header Name**: `Authorization`
* **Format**: `Bearer <PLAYER_TOKEN>`
* **Unauthorized Response (401 Unauthorized)**:
  ```json
  {
    "error": "You are not authorized to perform this action."
  }
  ```
* **Eliminated Player Response (403 Forbidden)**:
  ```json
  {
    "error": "You have been eliminated"
  }
  ```

### 3. ActionCable WebSocket Authentication
ActionCable authenticates incoming WebSocket connections during the handshake in `ApplicationCable::Connection`.

* **Connection URL**: `/cable` (e.g. `ws://localhost:3000/cable` or `wss://<host>/cable`)
* **Token Delivery Options**:
  * Query Parameter: `?token=<TOKEN>`
  * HTTP Header: `X-Auth-Token: <TOKEN>`
* If the token matches a record in `Host`, connection identifies as `current_host`.
* If the token matches a record in `Player`, connection identifies as `current_player`.
* If the token is missing or invalid, the connection is rejected (`reject_unauthorized_connection`).

---

## 1. Health Check / System

### Check Server Health
* **Section**: System Health
* **Endpoint**: `GET /up`
* **Auth Required**: No
* **Description**: Verifies that the Rails application has booted successfully and can respond to HTTP requests.
* **Success Response (200 OK)**:
  * Status: `200 OK` (HTML or empty response body).

---

## 2. Hosts Section

### List All Hosts
* **Section**: Host Management
* **Endpoint**: `GET /hosts`
* **Auth Required**: No
* **Description**: Returns all host records.
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
* **Description**: Creates a new game session owned by the authenticated host. Generates a random 6-character uppercase hex `game_code` (e.g. `"A3F8B2"`), seeds standard quiz questions via `QuizPopulator`, and broadcasts `game_created` and `host_joined` events to `game_room_<game_code>`.
* **Path Parameters**:
  * `id`: Host ID
* **Success Response (201 Created)**:
  ```json
  {
    "id": 10,
    "code": "A3F8B2"
  }
  ```
* **Error Response (422 Unprocessable Entity)**:
  ```json
  {
    "error": ["Host must exist"]
  }
  ```

### Host Rejoin Session
* **Section**: Host Management / Session Persistence
* **Endpoint**: `POST /hosts/rejoin`
* **Auth Required**: Yes (`Bearer <HOST_TOKEN>`)
* **Description**: Restores host state upon page refresh or reconnection. Verifies that the authenticated host owns the specified game.
* **Request Body**:
  ```json
  {
    "game_code": "A3F8B2"
  }
  ```
* **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "host": {
      "id": 1,
      "name": "Quiz Master Alex"
    },
    "game": {
      "id": 10,
      "game_code": "A3F8B2",
      "status": "in_progress",
      "current_round_id": 1,
      "current_question_id": 5,
      "players_count": 8
    }
  }
  ```
* **Error Responses**:
  * **401 Unauthorized**: Missing or invalid host token.
  * **404 Not Found**: Game not found with `game_code`.
    ```json
    {
      "error": "Game not found"
    }
    ```
  * **410 Gone**: Game has already concluded.
    ```json
    {
      "error": "Game is no longer active",
      "game_status": "completed"
    }
    ```

---

## 3. Games Section

### List All Games
* **Section**: Game Management
* **Endpoint**: `GET /games`
* **Auth Required**: No
* **Description**: Returns all games stored in the database.
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 10,
      "game_code": "A3F8B2",
      "host_id": 1,
      "player_limit": 8,
      "players_count": 8,
      "status": "in_progress",
      "current_round_id": 1,
      "current_question_id": 5,
      "question_started_at": "2026-11-13T09:00:00.000Z",
      "created_at": "2026-11-13T08:50:00.000Z",
      "updated_at": "2026-11-13T09:00:00.000Z"
    }
  ]
  ```

### Join Game / Create Player
* **Section**: Game Management / Player Lobby
* **Endpoint**: `POST /games/create_player`
* **Auth Required**: No
* **Description**: Enrolls a player into an existing game matching `game_code`. Checks player capacity (`player_limit`, default 8), generates a secure player session `token`, initializes player inventory with 3 default power-ups, and broadcasts a `player_joined` event via ActionCable.
* **Request Body**:
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
    "token": "a1b2c3d4e5f6...",
    "power_ups": [
      "get_hundred_points",
      "double_points",
      "glitch_sabotage"
    ],
    "active_power_up": null,
    "active_power_up_question_id": null,
    "created_at": "2026-11-13T08:55:00.000Z",
    "updated_at": "2026-11-13T08:55:00.000Z"
  }
  ```
* **Error Responses**:
  * **400 Bad Request**: Missing `game_code` parameter.
    ```json
    {
      "error": "must be provided"
    }
    ```
  * **404 Not Found**: Game not found with the provided code.
    ```json
    {
      "error": "Game not found"
    }
    ```
  * **422 Unprocessable Entity - Lobby Full**:
    ```json
    {
      "error": "has reached the maximum number of players"
    }
    ```
  * **422 Unprocessable Entity - Duplicate/Blank Username**:
    ```json
    {
      "username": [
        "is required"
      ]
    }
    ```

### Advance Game State Machine
* **Section**: Game Flow Orchestration
* **Endpoint**: `POST /games/:id/advance_step`
* **Auth Required**: Yes (`Bearer <HOST_TOKEN>`)
* **Description**: Advances the game state machine forward. The state flow proceeds as follows:
  1. `waiting` / unstarted $\rightarrow$ Starts Round 1 Question 1, sets status to `in_progress`, updates `shown_at` and `question_started_at`.
  2. `in_progress` (at end of round) $\rightarrow$ Triggers intermediate leaderboard, executes `RoundTransitionService` / `RoundResultsService` (evaluates knockout elimination, repopulates power-ups for survivors, identifies finalists/winner), and transitions to `round_summary`.
  3. `in_progress` (every 4th question) $\rightarrow$ If 4 questions have been shown in the round (`questions_shown_count % 4 == 0`), transitions to `leaderboard` and invokes `DisplayLeaderboardService`.
  4. `in_progress` (standard) $\rightarrow$ Advances to the next question in the current round.
  5. `leaderboard` $\rightarrow$ Resumes gameplay by advancing to the next question in the round.
  6. `round_summary` $\rightarrow$ Advances to Question 1 of the next round, or transitions to `completed` if the final round is finished.
* **Path Parameters**:
  * `id`: Game ID
* **Success Response (200 OK)**:
  ```json
  {
    "event": "game_state_changed",
    "game_id": 10,
    "status": "in_progress",
    "current_round_id": 1,
    "current_question": {
      "id": 5,
      "title": "Which planet is known as the Red Planet?",
      "question_type": "single_choice",
      "position": 1,
      "round_id": 1,
      "shown_at": "2026-11-13T09:00:00.000Z",
      "created_at": "2026-11-13T08:50:00.000Z",
      "updated_at": "2026-11-13T09:00:00.000Z",
      "options": [
        {
          "id": 1,
          "text": "Venus",
          "position": 1,
          "question_id": 5,
          "image_url": null
        },
        {
          "id": 2,
          "text": "Mars",
          "position": 2,
          "question_id": 5,
          "image_url": "https://storage.googleapis.com/.../mars.png"
        }
      ]
    },
    "question_started_at": "2026-11-13T09:00:00.000Z"
  }
  ```
* **Error Response (422 Unprocessable Entity)**:
  ```json
  {
    "error": "Failed to transition game state"
  }
  ```

### Get Active Players in Game
* **Section**: Game Management
* **Endpoint**: `GET /games/:game_id/get_players` (or with query param `?game_code=...`)
* **Auth Required**: No
* **Description**: Returns the list of player IDs and usernames enrolled in the specified game.
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
* **Description**: Returns all players across games.
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 5,
      "username": "PlayerOne",
      "score": 196,
      "eliminated": false,
      "game_id": 10,
      "token": "a1b2c3d4...",
      "power_ups": ["glitch_sabotage"],
      "created_at": "2026-11-13T08:55:00.000Z",
      "updated_at": "2026-11-13T09:05:00.000Z"
    }
  ]
  ```

### Get Player Details
* **Section**: Player Management
* **Endpoint**: `GET /players/:id`
* **Auth Required**: No
* **Path Parameters**:
  * `id`: Player ID
* **Success Response (200 OK)**:
  ```json
  {
    "id": 5,
    "username": "PlayerOne",
    "score": 196,
    "eliminated": false,
    "game_id": 10,
    "power_ups": ["glitch_sabotage"]
  }
  ```

### Player Rejoin Session
* **Section**: Player Management / Session Persistence
* **Endpoint**: `POST /players/rejoin`
* **Auth Required**: Yes (`Bearer <PLAYER_TOKEN>` header or `token` query/body param)
* **Description**: Validates player token and restores player and game state upon reconnection or browser refresh.
* **Request Body**:
  ```json
  {
    "game_code": "A3F8B2"
  }
  ```
* **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "player": {
      "id": 5,
      "username": "PlayerOne",
      "score": 196,
      "eliminated": false
    },
    "game": {
      "id": 10,
      "game_code": "A3F8B2",
      "status": "in_progress",
      "current_round_id": 1,
      "current_question_id": 5
    }
  }
  ```
* **Error Responses**:
  * **401 Unauthorized**: Invalid or missing player token.
    ```json
    {
      "error": "Invalid session token"
    }
    ```
  * **404 Not Found**: Game not found.
    ```json
    {
      "error": "Game not found"
    }
    ```
  * **410 Gone**: Game completed or cancelled.
    ```json
    {
      "error": "Game is no longer active",
      "game_status": "completed"
    }
    ```

---

## 5. Submissions Section

### Submit Answer
* **Section**: Gameplay / Submissions
* **Endpoint**: `POST /submissions`
* **Auth Required**: Yes (`Bearer <PLAYER_TOKEN>`)
* **Description**: Submits the player's answer for the active question. Calculates response duration, evaluates correctness against `correct_option_positions`, applies the dynamic time-decay scoring formula, applies any active deferred power-ups (`double_points`), updates player score, records the submission, and broadcasts `answer_submitted` via ActionCable.

#### Request Body Structure
```json
{
  "submission": {
    "question_id": 5,
    "answer": 2
  }
}
```

#### Answer Formats by Question Type
1. **`true_false` & `single_choice`**:
   * Value: Integer or string representing the option `position` (e.g. `1` or `2`).
2. **`drag_drop_order`**:
   * Value: Array of integers representing the ordered option positions (e.g. `[3, 1, 4, 2]`). Must match `correct_option_positions` in exact sequence.
3. **`type_the_answer`**:
   * Value: String representing the typed answer (e.g. `"Paris"`). Validated case-insensitively against matching option texts.

#### Scoring Rules (`ScoreCalculator` & `ScoreUpdater`)
* **Base Points**: `100` points for a correct answer.
* **Grace Period**: First `5,000 ms` (5 seconds) from `question_started_at` incur **0 point loss**.
* **Time Decay**: **-2 points lost per second** (1,000 ms) elapsed beyond 5 seconds.
* **Minimum Point Floor**: Correct answers never award fewer than `75` points.
* **Incorrect Answers**: `0` points awarded.
* **Power-Up Multiplier (`double_points`)**: If the player activated `double_points` prior to submission, awarded points are multiplied by `2` (e.g. 100 $\rightarrow$ 200, 75 $\rightarrow$ 150). The deferred power-up is consumed atomically.

* **Success Response (201 Created)**:
  ```json
  {
    "submission": {
      "id": 42,
      "player_id": 5,
      "question_id": 5,
      "round_id": 1,
      "answer": 2,
      "response_time_ms": 6800,
      "points_awarded": 98,
      "created_at": "2026-11-13T09:00:07.000Z",
      "updated_at": "2026-11-13T09:00:07.000Z"
    },
    "correct": true,
    "points_awarded": 98
  }
  ```

* **Error Responses**:
  * **403 Forbidden - Player Eliminated**:
    ```json
    {
      "error": "You have been eliminated"
    }
    ```
  * **422 Unprocessable Entity - Inactive Question**:
    ```json
    {
      "error": "That question is no longer active"
    }
    ```
  * **422 Unprocessable Entity - Duplicate Submission**:
    ```json
    {
      "error": "Answer already submitted for this question"
    }
    ```

---

## 6. Power-Ups Section

Each player begins the game with 3 power-ups. When surviving players advance to a new round, their power-ups are automatically replenished.

### Available Power-Ups Catalog
1. **`get_hundred_points`**:
   * Immediately awards 100 points, generates an automatic submission record with `answer: "get_hundred_points"`, and marks the question answered.
2. **`double_points`**:
   * Activates deferred doubling for the current question (`active_power_up: "double_points"`). If the player subsequently submits a correct answer, their score for that question is multiplied by 2.
3. **`glitch_sabotage`**:
   * Targeted attack against an active opponent in the same game room. Broadcasts a `glitch_attack` ActionCable event instructing the victim's client to render visual distortion for 10 seconds (`GLITCH_DURATION_MS = 10000`).

---

### Use Power-Up
* **Section**: Gameplay / Power-Ups
* **Endpoint**: `POST /power_ups/use`
* **Auth Required**: Yes (`Bearer <PLAYER_TOKEN>`)
* **Description**: Consumes and triggers a power-up from the player's active inventory.

#### 1. Glitch Sabotage (`power_name: "glitch_sabotage"`)
* **Request Body**:
  ```json
  {
    "power_up": {
      "question_id": 5,
      "power_name": "glitch_sabotage",
      "victim_player_id": 7
    }
  }
  ```
* **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "status": "sabotage_sent",
    "power_name": "glitch_sabotage",
    "victim_id": 7,
    "data": {
      "question_id": 5,
      "victim_player_id": 7,
      "glitch_duration_ms": 10000
    }
  }
  ```

#### 2. Get Hundred Points (`power_name: "get_hundred_points"`)
* **Request Body**:
  ```json
  {
    "power_up": {
      "question_id": 5,
      "power_name": "get_hundred_points"
    }
  }
  ```
* **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "status": "auto_submitted",
    "power_name": "get_hundred_points",
    "points_awarded": 100,
    "submission": {
      "id": 43,
      "player_id": 5,
      "question_id": 5,
      "points_awarded": 100,
      "answer": "get_hundred_points"
    },
    "data": {
      "points_awarded": 100,
      "correct": true
    }
  }
  ```

#### 3. Double Points (`power_name: "double_points"`)
* **Request Body**:
  ```json
  {
    "power_up": {
      "question_id": 5,
      "power_name": "double_points"
    }
  }
  ```
* **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "status": "activated",
    "power_name": "double_points",
    "active_power_up": "double_points",
    "data": {
      "active_power_up": "double_points"
    }
  }
  ```

* **Error Responses**:
  * **400 Bad Request**: Invalid power-up name or missing parameters.
    ```json
    {
      "success": false,
      "error": "Invalid power-up: invisible_shield"
    }
    ```
  * **404 Not Found**: Question or target victim not found.
    ```json
    {
      "success": false,
      "error": "Couldn't find Question with 'id'=999"
    }
    ```
  * **422 Unprocessable Entity - Validation Failure**:
    ```json
    {
      "success": false,
      "error": "Power-up not available"
    }
    ```
    *(Other error causes: `"Game is not accepting submissions"`, `"Question already answered"`, `"Cannot sabotage yourself"`, `"Target player not found or eliminated"`).*

---

## 7. Rounds Section

### List All Rounds
* **Section**: Quiz / Round Management
* **Endpoint**: `GET /rounds`
* **Auth Required**: No
* **Description**: Returns all rounds with nested questions and options ordered by position (`correct_option_positions` excluded from question serializations).
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 1,
      "title": "Round 1 - Quarter-Finals",
      "game_id": 10,
      "position": 1,
      "questions": [
        {
          "id": 1,
          "title": "What is the capital of France?",
          "question_type": "single_choice",
          "position": 1,
          "round_id": 1,
          "options": [
            {
              "id": 1,
              "text": "Paris",
              "position": 1,
              "image_url": null
            },
            {
              "id": 2,
              "text": "London",
              "position": 2,
              "image_url": null
            }
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
* **Path Parameters**:
  * `id`: Round ID
* **Success Response (200 OK)**:
  ```json
  {
    "id": 1,
    "title": "Round 1 - Quarter-Finals",
    "game_id": 10,
    "position": 1,
    "questions": [...]
  }
  ```

### Create a Round
* **Section**: Quiz / Round Management
* **Endpoint**: `POST /rounds`
* **Auth Required**: No
* **Description**: Creates a new round with optional nested questions and options.
* **Request Body**:
  ```json
  {
    "round": {
      "title": "Round 1 - Quarter-Finals",
      "game_id": 10,
      "position": 1,
      "questions_attributes": [
        {
          "title": "What is 2 + 2?",
          "question_type": 1,
          "correct_option_positions": [1],
          "options_attributes": [
            { "text": "4", "position": 1 },
            { "text": "5", "position": 2 }
          ]
        }
      ]
    }
  }
  ```
* **Success Response (201 Created)**: Returns the persisted round object.
* **Error Response (422 Unprocessable Entity)**:
  ```json
  {
    "errors": [
      "Title can't be blank"
    ]
  }
  ```

---

## 8. Questions & Options Section

### Question Types (Enum Values)
* `0`: `true_false`
* `1`: `single_choice`
* `2`: `multiple_choice`
* `3`: `drag_drop_order`
* `4`: `type_the_answer`

### List All Questions
* **Section**: Question & Options Management
* **Endpoint**: `GET /questions`
* **Auth Required**: No
* **Description**: Returns all questions with attached options and image URLs (`correct_option_positions` excluded).
* **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 1,
      "title": "What is 2 + 2?",
      "question_type": "single_choice",
      "position": 1,
      "round_id": 1,
      "options": [
        {
          "id": 1,
          "text": "4",
          "position": 1,
          "image_url": null
        }
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
* **Success Response (200 OK)**: Returns the single question object.

### Create Question
* **Section**: Question & Options Management
* **Endpoint**: `POST /questions`
* **Auth Required**: Yes (`Bearer <HOST_TOKEN>`)
* **Description**: Creates a question with nested options and specifies `correct_option_positions`.
* **Request Body**:
  ```json
  {
    "question": {
      "title": "Which planet is known as the Red Planet?",
      "question_type": "single_choice",
      "round_id": 1,
      "position": 1,
      "correct_option_positions": [2],
      "options_attributes": [
        { "text": "Venus", "position": 1 },
        { "text": "Mars", "position": 2 }
      ]
    }
  }
  ```
* **Success Response (201 Created)**: Returns created question object.
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
* **Success Response (200 OK)**: Returns the updated question with included options.

---

## 9. Tournament Progression & Knockout Elimination

The tournament operates on a structured stage reduction model:

```
Round 1: Quarter-Finals (8 Players)
   │
   ▼ [Eliminate Bottom 50% / Lowest 4 Scorers]
Round 2: Semi-Finals (4 Players)
   │
   ▼ [Eliminate Bottom 50% / Lowest 2 Scorers]
Round 3: Finals (2 Players)
   │
   ▼ [Determine 1 Champion Winner]
Tournament Finished
```

### Elimination Rules (`PlayerAdvancementService` & `PlayerEliminationService`)
1. **Rank Criteria**: Players are ordered by `score` descending, with `created_at` ascending as secondary tie-breaker.
2. **50% Cutoff**: `target_advancing_count = (active_count / 2.0).ceil`.
3. **Database Flag**: Eliminated players have `eliminated` set to `true`. They are prevented from submitting answers or using power-ups in subsequent rounds.
4. **Power-Up Reset**: Players who survive and advance have their `power_ups` array refreshed back to `['get_hundred_points', 'double_points', 'glitch_sabotage']` at the start of the next round.
5. **Intermediate Leaderboard**: Displayed every 4 questions (`LEADERBOARD_QUESTION_INTERVAL = 4`) during a round via `DisplayLeaderboardService`.

---

## 10. Real-Time WebSockets (ActionCable)

### Connection URL & Parameters
* **URL**: `/cable` (`ws://localhost:3000/cable`)
* **Handshake Authentication**:
  * Pass query parameter `?token=<TOKEN>` or HTTP header `X-Auth-Token: <TOKEN>`.
  * Verified in `ApplicationCable::Connection`.

### Channel: `GameChannel`
* **Subscription Parameters**:
  ```json
  {
    "command": "subscribe",
    "identifier": "{\"channel\":\"GameChannel\",\"game_code\":\"A3F8B2\"}"
  }
  ```
* **Subscription Authorization**:
  * Hosts can subscribe only if they own the game (`connection.current_host.id == game.host_id`).
  * Players can subscribe only if they are enrolled in the game (`game.players.exists?(id: connection.current_player.id)`).
* **Broadcast Stream**: `game_room_<game_code>`

---

### Inbound Client Socket Actions

#### 1. `submit_answer`
* **Payload**:
  ```json
  {
    "command": "message",
    "identifier": "{\"channel\":\"GameChannel\",\"game_code\":\"A3F8B2\"}",
    "data": "{\"action\":\"submit_answer\",\"player_id\":5}"
  }
  ```
* **Immediate Broadcast**: Sends `answer_submitted` event with `status: "waiting_for_results"`.

---

### Outbound Server Broadcast Events

#### 1. `game_created`
* **Triggered By**: `POST /hosts/:id/create_game`
```json
{
  "event": "game_created",
  "game_code": "A3F8B2",
  "total_players": 0
}
```

#### 2. `host_joined`
* **Triggered By**: `POST /hosts/:id/create_game`
```json
{
  "event": "host_joined",
  "host": {
    "id": 1,
    "name": "Quiz Master Alex"
  }
}
```

#### 3. `player_joined`
* **Triggered By**: `POST /games/create_player`
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

#### 4. `game_state_changed`
* **Triggered By**: `POST /games/:id/advance_step`
```json
{
  "event": "game_state_changed",
  "game_id": 10,
  "status": "in_progress",
  "current_round_id": 1,
  "current_question": {
    "id": 5,
    "title": "What is the capital of France?",
    "question_type": "single_choice",
    "position": 1,
    "round_id": 1,
    "options": [
      { "id": 1, "text": "Paris", "position": 1, "image_url": null },
      { "id": 2, "text": "London", "position": 2, "image_url": null }
    ]
  },
  "question_started_at": "2026-11-13T09:00:00.000Z"
}
```

#### 5. `answer_submitted`
* **Triggered By**: `POST /submissions` or `AutoSubmit100Service`
```json
{
  "event": "answer_submitted",
  "player_id": 5,
  "player_name": "PlayerOne",
  "power_ups": ["glitch_sabotage"],
  "question_id": 5,
  "players_submitted": 4,
  "total_players": 8
}
```

#### 6. `glitch_attack`
* **Triggered By**: `POST /power_ups/use` (`power_name: "glitch_sabotage"`)
```json
{
  "event": "glitch_attack",
  "initiator_id": 5,
  "initiator_name": "PlayerOne",
  "victim_id": 7,
  "victim_name": "PlayerTwo",
  "question_id": 5,
  "glitch_duration_ms": 10000
}
```

#### 7. `display_leaderboard`
* **Triggered By**: `DisplayLeaderboardService` (every 4th question during a round)
```json
{
  "event": "display_leaderboard",
  "round_id": 1,
  "round_title": "Round 1 - Quarter-Finals",
  "players": [
    {
      "id": 5,
      "username": "PlayerOne",
      "score": 384,
      "eliminated": false
    },
    {
      "id": 6,
      "username": "PlayerTwo",
      "score": 290,
      "eliminated": false
    }
  ]
}
```

#### 8. `round_results`
* **Triggered By**: `RoundResultsService` (end of round)
```json
{
  "event": "round_results",
  "round_id": 1,
  "round_title": "Round 1 - Quarter-Finals",
  "players": [
    { "id": 5, "username": "PlayerOne", "score": 400, "eliminated": false },
    { "id": 6, "username": "PlayerTwo", "score": 380, "eliminated": false },
    { "id": 7, "username": "PlayerThree", "score": 350, "eliminated": false },
    { "id": 8, "username": "PlayerFour", "score": 320, "eliminated": false },
    { "id": 9, "username": "PlayerFive", "score": 280, "eliminated": true },
    { "id": 10, "username": "PlayerSix", "score": 250, "eliminated": true },
    { "id": 11, "username": "PlayerSeven", "score": 210, "eliminated": true },
    { "id": 12, "username": "PlayerEight", "score": 190, "eliminated": true }
  ],
  "winner": null,
  "finalists": []
}
```
*(In Round 2 semi-finals, `finalists` contains the 2 advancing players; in Round 3 finals, `winner` contains the champion).*

#### 9. `round_summary`
* **Triggered By**: `RoundTransitionService` (end of round summary status)
```json
{
  "event": "round_summary",
  "game_id": 10,
  "round_id": 1
}
```

#### 10. `question_review`
* **Triggered By**: `QuestionTransitionService`
```json
{
  "event": "question_review",
  "question_id": 5,
  "correct_option_positions": [1]
}
```

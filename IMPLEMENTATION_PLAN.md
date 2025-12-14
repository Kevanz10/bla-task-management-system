# Task Management System - Implementation Plan

## 1. High-Level Architecture

### Application Structure
```
app/
  controllers/
    api/
      v1/
        auth/
          registrations_controller.rb    # User registration
          sessions_controller.rb          # User login
        tasks_controller.rb               # RESTful endpoints (requires auth)
    application_controller.rb             # Base controller with error handling
    concerns/
      jwt_authenticatable.rb              # JWT authentication concern
  models/
    task.rb                               # Task model
    user.rb                               # User model with password auth
  services/
    tasks/
      create.rb                           # Task creation logic
      update.rb                           # Task update logic
      destroy.rb                          # Task deletion logic
    auth/
      authenticate_user.rb                # User authentication service
      register_user.rb                    # User registration service
  lib/
    jwt_token.rb                          # JWT encoding/decoding utility
db/
  migrate/
    create_tasks.rb                       # Tasks table migration
    add_password_to_users.rb              # Add password_digest to users (if needed)
```

### Request Flow
```
HTTP Request → Routes → Authentication (JWT check) 
  → API::V1::TasksController → Service Object 
  → Model → Database → JSON Response
```

---

## 2. Data Model Overview

### Task Model
- **Primary Key**: UUID (Rails 8 default)
- **Attributes**:
  - `title` (string, required)
  - `description` (text, optional)
  - `status` (enum: pending, in_progress, completed)
  - `due_date` (date, optional)
  - `user_id` (uuid, foreign key to users, required)
  - `created_at` (timestamp)
  - `updated_at` (timestamp)

### User Model (Authentication)
- **Primary Key**: UUID (Rails 8 default)
- **Attributes**:
  - `email` (string, required, unique)
  - `password_digest` (string, required) - bcrypt encrypted
  - `created_at` (timestamp)
  - `updated_at` (timestamp)

### Database Schema
```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR NOT NULL,
  description TEXT,
  status VARCHAR NOT NULL DEFAULT 'pending',
  due_date DATE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Indexes
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
```

### Model Validations

**Task Model:**
- `title`: presence, length (min: 1, max: 255)
- `status`: inclusion in ['pending', 'in_progress', 'completed']
- `user_id`: presence
- `due_date`: optional, but if present should be valid date

**User Model:**
- `email`: presence, uniqueness, format validation
- `password`: presence (on create), minimum length (6 characters)
- `password_digest`: presence

### Associations
- Task `belongs_to :user`
- User `has_many :tasks`

---

## 3. API Endpoints

### Authentication Endpoints

| Method | Endpoint | Action | Description | Auth Required |
|--------|----------|--------|-------------|---------------|
| POST | `/api/v1/auth/register` | register | Create new user account | No |
| POST | `/api/v1/auth/login` | login | Authenticate user and get JWT token | No |

### Task Endpoints

| Method | Endpoint | Action | Description | Auth Required |
|--------|----------|--------|-------------|---------------|
| GET | `/api/v1/tasks` | index | List all tasks for current user | Yes |
| POST | `/api/v1/tasks` | create | Create a new task | Yes |
| GET | `/api/v1/tasks/:id` | show | Get a specific task | Yes |
| PATCH/PUT | `/api/v1/tasks/:id` | update | Update a task | Yes |
| DELETE | `/api/v1/tasks/:id` | destroy | Delete a task | Yes |

### Authentication Header
All authenticated requests require:
```
Authorization: Bearer <jwt_token>
```

### Request/Response Examples

#### Register User
**POST /api/v1/auth/register**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

**Success Response (201)**
```json
{
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "created_at": "2025-12-15T10:00:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Login User
**POST /api/v1/auth/login**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

**Success Response (200)**
```json
{
  "user": {
    "id": "user-uuid",
    "email": "user@example.com"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Response (401)**
```json
{
  "errors": [
    {
      "status": "401",
      "title": "Unauthorized",
      "detail": "Invalid email or password"
    }
  ]
}
```

#### Create Task
**POST /api/v1/tasks**
**Headers:** `Authorization: Bearer <jwt_token>`
```json
{
  "task": {
    "title": "Complete API documentation",
    "description": "Write comprehensive API docs",
    "status": "pending",
    "due_date": "2025-12-31"
  }
}
```
**Note:** `user_id` is automatically set from JWT token (current_user)

**Success Response (201)**
```json
{
  "id": "task-uuid",
  "title": "Complete API documentation",
  "description": "Write comprehensive API docs",
  "status": "pending",
  "due_date": "2025-12-31",
  "user_id": "user-uuid-from-jwt",
  "created_at": "2025-12-15T10:00:00Z",
  "updated_at": "2025-12-15T10:00:00Z"
}
```

**Error Response (422)**
```json
{
  "errors": [
    {
      "status": "422",
      "title": "Invalid params",
      "detail": "Title can't be blank"
    }
  ]
}
```

#### List Tasks
**GET /api/v1/tasks**
**Headers:** `Authorization: Bearer <jwt_token>`

**Success Response (200)**
```json
{
  "tasks": [
    {
      "id": "task-uuid-1",
      "title": "Task 1",
      "status": "pending",
      "user_id": "user-uuid-from-jwt",
      ...
    }
  ]
}
```
**Note:** Only returns tasks belonging to the authenticated user

#### Update Task
**PATCH /api/v1/tasks/:id**
**Headers:** `Authorization: Bearer <jwt_token>`
```json
{
  "task": {
    "status": "in_progress"
  }
}
```

#### Authentication Error (401)
**Any endpoint without valid JWT token**
```json
{
  "errors": [
    {
      "status": "401",
      "title": "Unauthorized",
      "detail": "Invalid or missing authentication token"
    }
  ]
}
```

#### Delete Task
**DELETE /api/v1/tasks/:id**
**Success Response (204 No Content)**

---

## 4. Implementation Steps

### Step 0: Dependencies & Configuration
1. Add gems to `Gemfile`:
   - `jwt` - JWT token encoding/decoding
   - `bcrypt` - Password hashing (if not already present)
2. Add JWT secret to Rails credentials/config:
   - Use `Rails.application.credentials.jwt_secret` or `ENV['JWT_SECRET']`
   - Generate secret: `rails secret` or use `SecureRandom.hex(64)`

### Step 1: Database Setup
1. Generate migration for users (if User model doesn't exist):
   - `rails g migration CreateUsers email password_digest`
   - Add email uniqueness index
2. Generate migration: `rails g migration CreateTasks`
3. Create tasks table with:
   - UUID primary key
   - All required fields
   - Foreign key to users
   - Indexes on user_id, status, due_date
   - Database-level constraints (NOT NULL on title, status, user_id)
   - Enum constraint for status values

### Step 2: User Model (Authentication)
1. Update `app/models/user.rb`
2. Add:
   - `has_secure_password` (bcrypt)
   - `has_many :tasks` association
   - Validations:
     - Email: presence, uniqueness, format
     - Password: presence (on create), minimum length
   - Method: `generate_jwt_token` (optional helper)

### Step 3: Task Model
1. Create `app/models/task.rb`
2. Define:
   - `belongs_to :user` association
   - Enum for status: `pending`, `in_progress`, `completed`
   - Validations:
     - Title: presence, length
     - Status: inclusion validation
     - User: presence (validated via association)
   - Scopes (optional but useful):
     - `by_status(status)`
     - `due_before(date)`
     - `due_after(date)`

### Step 4: JWT Utility
1. Create `app/lib/jwt_token.rb` (or `app/services/jwt_token.rb`)
2. Implement:
   - `encode(payload)` - Encode user_id into JWT token
   - `decode(token)` - Decode JWT token and return user_id
   - Use HS256 algorithm
   - Set expiration (e.g., 24 hours)
   - Handle decode errors gracefully

### Step 5: Service Objects

**Authentication Services:**
1. **Auth::RegisterUser** (`app/services/auth/register_user.rb`)
   - Accepts email and password
   - Creates user with hashed password
   - Returns user and JWT token on success
   - Returns errors on failure

2. **Auth::AuthenticateUser** (`app/services/auth/authenticate_user.rb`)
   - Accepts email and password
   - Finds user by email
   - Verifies password using `authenticate` method
   - Returns user and JWT token on success
   - Returns error on failure

**Task Services:**
3. **Tasks::Create** (`app/services/tasks/create.rb`)
   - Accepts params and user (not user_id)
   - Builds task with user association
   - Saves task
   - Returns success/failure pattern
   
4. **Tasks::Update** (`app/services/tasks/update.rb`)
   - Accepts task, params
   - Updates attributes
   - Returns success/failure pattern
   
5. **Tasks::Destroy** (`app/services/tasks/destroy.rb`)
   - Accepts task
   - Destroys record
   - Returns success/failure pattern

### Step 6: Authentication Concern
1. Create `app/controllers/concerns/jwt_authenticatable.rb`
2. Implement:
   - `authenticate_user!` - Extract JWT from Authorization header
   - `current_user` - Load user from JWT token
   - `decode_jwt_token` - Helper to decode token
   - Handle missing/invalid tokens (raise errors)

### Step 7: Controllers

1. **ApplicationController**
   - Include `JwtAuthenticatable` concern
   - Error handling with `rescue_from`:
     - `JWT::DecodeError` → 401 Unauthorized
     - `JWT::ExpiredSignature` → 401 Unauthorized
     - `ActiveRecord::RecordNotFound` → 404 Not Found
     - `ActiveRecord::RecordInvalid` → 422 Unprocessable Entity
   - Standardized JSON error format
   - Response helpers

2. **API::V1::Auth::RegistrationsController**
   - `create` action
   - Calls `Auth::RegisterUser` service
   - Returns user and token on success
   - Returns errors on failure

3. **API::V1::Auth::SessionsController**
   - `create` action (login)
   - Calls `Auth::AuthenticateUser` service
   - Returns user and token on success
   - Returns 401 on failure

4. **API::V1::TasksController**
   - Include authentication via `before_action :authenticate_user!`
   - Thin actions (max 7 logical lines each)
   - `index`: Use `current_user.tasks` to list only user's tasks
   - `show`: Use `current_user.tasks.find(params[:id])` - raises 404 if not owner
   - `create`: Create task via service (associates with current_user)
   - `update`: Use `current_user.tasks.find(params[:id])` then update via service
   - `destroy`: Use `current_user.tasks.find(params[:id])` then destroy via service
   - Strong params method (no user_id needed - from current_user)
   
   **Authorization Pattern:**
   - Use Rails association scoping: `current_user.tasks.find(id)` instead of `Task.find(id)`
   - Automatically restricts queries to user's tasks only
   - Raises `ActiveRecord::RecordNotFound` (404) if task doesn't belong to user
   - Simple, idiomatic Rails - no additional authorization logic needed

### Step 8: Routes
1. Namespace routes under `/api/v1`
2. Authentication routes:
   - `post '/auth/register', to: 'auth/registrations#create'`
   - `post '/auth/login', to: 'auth/sessions#create'`
3. Resourceful routes for tasks (requires authentication):
   - `resources :tasks, only: [:index, :show, :create, :update, :destroy]`

### Step 9: Error Handling
1. Centralized error handling in ApplicationController (covered in Step 7)
2. Standard JSON error envelope format
3. Handle:
   - JWT decode errors → 401
   - JWT expired → 401
   - Invalid credentials → 401
   - ActiveRecord validation errors → 422
   - Record not found → 404 (includes cases where task exists but doesn't belong to user)
   - Parameter errors → 400

**Note:** Using scoped queries (`current_user.tasks.find`) means unauthorized access attempts return 404 (Not Found) rather than 403 (Forbidden), which prevents information disclosure about whether a task ID exists for another user.

---

## 5. Key Design Decisions

### Authentication Approach
- **JWT-based authentication**: Minimal and pragmatic implementation
- **JWT library**: Use `jwt` gem directly (no Devise::JWT overhead)
- **Token storage**: Client-side only (no server-side token storage needed)
- **Password hashing**: bcrypt via `has_secure_password`
- **Token expiration**: 24 hours (configurable)
- **Authorization**: Users can only access/modify their own tasks via scoped queries

### Authorization Strategy (Scoped Queries)
**Simple and Pragmatic Approach:**
- Use Rails association scoping: `current_user.tasks.find(id)` instead of `Task.find(id)`
- Leverages `has_many :tasks` association on User model
- Automatically restricts all queries to user's own tasks
- Raises `ActiveRecord::RecordNotFound` (404) if task doesn't belong to user
- No additional authorization code needed - Rails associations handle it

**Implementation:**
```ruby
# Controller actions
def show
  task = current_user.tasks.find(params[:id])  # Auto-scoped to user
  render json: task
end

def update
  task = current_user.tasks.find(params[:id])  # Auto-scoped to user
  result = Tasks::Update.call(task, task_params)
  # ... render response
end
```

**Why this works:**
- Rails associations automatically scope queries
- If task with given ID doesn't belong to current_user, `find` raises RecordNotFound
- Returns 404 (Not Found) - prevents information disclosure about other users' tasks
- KISS principle - no extra gems, concerns, or complex logic needed

### Simplified Approach
- **No serialization library**: Direct `as_json` or manual JSON rendering
- **Service objects**: Keep controllers thin, business logic in services
- **ServiceResult pattern**: Simple success/failure return from services
- **Authentication concern**: Reusable JWT authentication logic

### ServiceResult Pattern
```ruby
# Simple pattern - return object on success, false on failure
# Services return the task object or raise/return errors
```

### Error Response Format
Following the standard error envelope:
```json
{
  "errors": [
    {
      "status": "422",
      "title": "Invalid params",
      "detail": "Validation error message"
    }
  ]
}
```

---

## 6. Testing Strategy (Future)

- RSpec request specs for all endpoints
- Model specs for validations and associations
- Service object specs
- FactoryBot for test data
- One expectation per example

---

## 7. File Structure Summary

**New Files to Create:**
```
app/models/task.rb
app/models/user.rb (or update if exists)
app/lib/jwt_token.rb (or app/services/jwt_token.rb)
app/controllers/concerns/jwt_authenticatable.rb
app/controllers/api/v1/auth/registrations_controller.rb
app/controllers/api/v1/auth/sessions_controller.rb
app/controllers/api/v1/tasks_controller.rb
app/services/auth/register_user.rb
app/services/auth/authenticate_user.rb
app/services/tasks/create.rb
app/services/tasks/update.rb
app/services/tasks/destroy.rb
db/migrate/YYYYMMDDHHMMSS_create_users.rb (if needed)
db/migrate/YYYYMMDDHHMMSS_create_tasks.rb
```

**Files to Modify:**
```
Gemfile (add jwt, bcrypt)
config/routes.rb (add API routes)
app/controllers/application_controller.rb (add error handling and JWT concern)
config/application.rb (or credentials) (add JWT secret)
```

---

## 8. JWT Implementation Details

### JWT Token Structure
```ruby
# Payload
{
  user_id: "uuid-here",
  exp: timestamp (24 hours from now),
  iat: current_timestamp
}

# Algorithm: HS256
# Secret: Rails.application.credentials.jwt_secret or ENV['JWT_SECRET']
```

### Token Usage
1. Client registers/logs in → Receives JWT token
2. Client includes token in `Authorization: Bearer <token>` header
3. Server validates token on each request
4. Server extracts `user_id` from token to set `current_user`
5. All task operations use `current_user` (no user_id in params)

### Security Considerations
- Token stored client-side only
- HTTPS recommended in production
- Token expiration prevents indefinite access
- Password hashed with bcrypt (no plain text storage)
- JWT secret should be strong and kept secure

## 9. Assumptions

1. User model may need to be created or updated with email/password_digest
2. Rails 8 API-only mode is configured
3. PostgreSQL 16 is the database
4. UUID extension (pgcrypto) is enabled
5. No need for pagination in initial implementation
6. No need for filtering/searching in initial implementation
7. JWT secret can be stored in Rails credentials or environment variable
8. Token refresh mechanism not needed for initial implementation

---

## Next Steps

1. Review and approve this plan
2. Implement Step 0 (Dependencies & Configuration)
3. Implement Step 1 (Database migrations)
4. Implement Step 2 (User Model)
5. Implement Step 3 (Task Model)
6. Implement Step 4 (JWT Utility)
7. Implement Step 5 (Service Objects)
8. Implement Step 6 (Authentication Concern)
9. Implement Step 7 (Controllers)
10. Implement Step 8 (Routes)
11. Implement Step 9 (Error Handling - integrated in Step 7)
12. Test endpoints manually or with request specs

## Implementation Order Summary

**Phase 1: Authentication Foundation**
- JWT utility
- User model with password
- Authentication services
- Authentication controllers
- JWT authenticatable concern

**Phase 2: Tasks CRUD**
- Task model
- Task services
- Tasks controller
- Routes
- Error handling

This order ensures authentication is in place before building protected task endpoints.

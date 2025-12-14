require "rails_helper"

RSpec.describe "Tasks API", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:token) { JwtToken.encode(user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/tasks" do
    let!(:user_task) { create(:task, user: user) }
    let!(:other_task) { create(:task, user: other_user) }

    context "when authenticated" do
      it "returns only user's tasks" do
        get "/api/v1/tasks", headers: headers

        json = JSON.parse(response.body)
        expect(json["tasks"].length).to eq(1)
        expect(json["tasks"].first["id"]).to eq(user_task.id)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/tasks"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/tasks/:id" do
    let!(:task) { create(:task, user: user) }

    context "when authenticated and task belongs to user" do
      it "returns the task" do
        get "/api/v1/tasks/#{task.id}", headers: headers

        json = JSON.parse(response.body)
        expect(json["id"]).to eq(task.id)
      end
    end

    context "when task belongs to another user" do
      let!(:other_task) { create(:task, user: other_user) }

      it "returns not found" do
        get "/api/v1/tasks/#{other_task.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/tasks/#{task.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/tasks" do
    let(:task_params) do
      {
        task: {
          title: "New Task",
          description: "Task description",
          status: "pending",
          due_date: 7.days.from_now.to_date.to_s
        }
      }
    end

    context "with valid params" do
      it "creates a new task" do
        expect {
          post "/api/v1/tasks", params: task_params, headers: headers
        }.to change(Task, :count).by(1)
      end

      it "associates task with current user" do
        post "/api/v1/tasks", params: task_params, headers: headers

        json = JSON.parse(response.body)
        expect(json["user_id"]).to eq(user.id)
        expect(json["title"]).to eq("New Task")
      end
    end

    context "with missing title" do
      it "returns validation errors" do
        task_params[:task][:title] = ""
        post "/api/v1/tasks", params: task_params, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end

    context "with invalid status" do
      it "raises argument error" do
        task_params[:task][:status] = "invalid_status"

        expect {
          post "/api/v1/tasks", params: task_params, headers: headers
        }.to raise_error(ArgumentError, /is not a valid status/)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/tasks", params: task_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v1/tasks/:id" do
    let!(:task) { create(:task, user: user, title: "Original Title") }

    context "with valid params" do
      it "updates the task" do
        patch "/api/v1/tasks/#{task.id}",
              params: { task: { title: "Updated Title" } },
              headers: headers

        json = JSON.parse(response.body)
        expect(json["title"]).to eq("Updated Title")
      end
    end

    context "when task belongs to another user" do
      let!(:other_task) { create(:task, user: other_user) }

      it "returns not found" do
        patch "/api/v1/tasks/#{other_task.id}",
              params: { task: { title: "Updated Title" } },
              headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with invalid params" do
      it "returns validation errors" do
        patch "/api/v1/tasks/#{task.id}",
              params: { task: { title: "" } },
              headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    let!(:task) { create(:task, user: user) }

    context "when task belongs to user" do
      it "deletes the task" do
        expect {
          delete "/api/v1/tasks/#{task.id}", headers: headers
        }.to change(Task, :count).by(-1)

        expect(response.body).to be_empty
      end
    end

    context "when task belongs to another user" do
      let!(:other_task) { create(:task, user: other_user) }

      it "returns not found" do
        delete "/api/v1/tasks/#{other_task.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

module Api
  module V1
    class TasksController < ApplicationController
      before_action :authenticate_user!

      def index
        tasks = current_user.tasks
        render json: { tasks: tasks }
      end

      def show
        task = current_user.tasks.find(params[:id])
        render json: task
      end

      def create
        task = current_user.tasks.build(task_params)
        task.save!
        render json: task, status: :created
      end

      def update
        task = current_user.tasks.find(params[:id])
        task.update!(task_params)
        render json: task
      end

      def destroy
        task = current_user.tasks.find(params[:id])
        task.destroy
        head :no_content
      end

      private

      def task_params
        params.require(:task).permit(:title, :description, :status, :due_date)
      end
    end
  end
end

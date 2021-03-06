module Course
  class QuizzesController < CourseAdminController
    before_action :check_lesson_id, only: [:index, :create]
    before_action :set_course_quiz, only: [:show, :update, :destroy]

    # GET /course/quizzes.json
    def index
      lesson = Course::Lesson.find(params[:lesson_id])
      @course_quizzes = lesson.course_quizs.sort_by(&:created_at)
      if !current_user || (current_user && !current_user.is_admin?)
        @course_quizzes.each { |quiz| quiz.data.delete('answer_idx') }
      end

      query = Course::UserCourse.where(course_course_datum: lesson.course_course_datum, user: current_user)

      if current_user && query.exists?
        user_course = query.first
        json_response = {} # mock only
        Course::CourseChecker.check_lesson user_course, lesson, json_response
      end
    end

    # GET /course/quizzes/1.json
    def show
      if !current_user || (current_user && !current_user.is_admin?)
        @course_quiz.data.delete('answer_idx')
      end
    end

    # POST /course/quizzes.json
    def create
      lesson = Course::Lesson.find(params[:lesson_id])
      @course_quiz = Course::Quiz.new
      lesson.course_quizs << @course_quiz

      respond_to do |format|
        if @course_quiz.save
          format.json { render :show, status: :created, location: @course_quiz }
        else
          format.json { render json: @course_quiz.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /course/quizzes/1.json
    def update
      @course_quiz[:data] = @course_quiz.data.merge(JSON.parse(request.body.read))
      respond_to do |format|
        if @course_quiz.save
          format.json { render :show, status: :ok, location: @course_quiz }
        else
          format.json { render json: @course_quiz.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /course/quizzes/1.json
    def destroy
      @course_quiz.destroy
      respond_to do |format|
        format.json { head :no_content }
      end
    end

    private

    def set_course_quiz
      @course_quiz = Course::Quiz.find(params[:id])
    end

    def check_lesson_id
      if !params.key?(:lesson_id) || (params.key?(:lesson_id) && !Course::Lesson.where(id: params[:lesson_id]).exists?)
        fail Exceptions::NotFound
      end
    end
  end
end

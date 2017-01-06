class CourseInfoPresenter < PrivatePresenter
  def_delegators :@course, :id, :course_code, :title, :abstract,
                           :start_date, :end_date, :display_start_date,
                           :available?, :was_available?, :lang, :classifiers,
                           :alternative_teacher_text, :enrollment_delta,
                           :external_course_url, :hidden, :affiliated, :fullstate,
                           :channel

  def self.build(course, enrollments = nil)
    new course: course, enrollments: enrollments
  end

  include Rails.application.routes.url_helpers

  def visual?
    @course.visual_id
  end

  def course_visual_path size = nil
    if @course.visual_id
      file_path id: @course.visual_id, size: size
    else
      if size
        filename = "course_#{size.to_s}_#{Xikolo.config.brand}.png"
      else
        filename = "course_#{Xikolo.config.brand}.png"
      end
       ActionController::Base.helpers.asset_path 'defaults/' + filename
    end
  end

  def course_visual_url host, size: nil, secure: true
    protocol = secure ? 'https' : 'http'
    if @course.visual_id
      file_url id: @course.visual_id, size: size, protocol: protocol, host: host
    else
      filename = "course_#{(size ? "#{size.to_s}_" : '')}#{Xikolo.config.brand}.png"
      ActionController::Base.helpers.asset_url 'defaults/' + filename, protocol: protocol, host: host
    end
  end

  def enrollment
    return nil if @enrollments.nil?
    @enrollment ||= @enrollments.find { |enrollment| enrollment.course_id == id }
  end

  # returns true for all type of enrollments
  def enrolled?
    !enrollment.nil?
  end

  def external?
    !@course.external_course_url.nil? && !@course.external_course_url.empty?
  end

  def external_course_delay
    return 0 if !external? || enrollment.nil?
    diff = ((DateTime.now - enrollment.created_at) * 24 * 60 * 60).to_i
    max_delay = @course.external_course_delay
    [0, max_delay-diff].max
  end

  def show_social_media_buttons?
    !(Xikolo.config.site_name == 'openSAP.cn' || @course.hidden || @course.affiliated)
  end

  def teacher_names
    @course.teacher_text
  end
  alias_method :teachers, :teacher_names

  def to_param
    course_code
  end

  def enrollment_id
    UUID4.try_convert(enrollment.try(:id)).to_s
  end

  def meta_tags(request)
    {   title: @course.title + ' - ' + @course.teacher_text,
        description: @course.abstract,
        og: {
            # mandatory:
            title: @course.title,
            type: 'website',
            image: course_visual_url(request.host, secure: true),
            url: course_url(@course.course_code, host: request.host),
            # optional
            description: @course.abstract,
            site_name: Xikolo.config.site_name,
            'image:secure_url' => course_visual_url(request.host)
        }
    }
  end

  def invite_only?
    @course.invite_only
  end
end

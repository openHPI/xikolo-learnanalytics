class QcAlertConsumer < Msgr::Consumer

  def pinboard_report
    payload = @message.payload
    @message.ack
    # Get all users that this report is relevant for
    # This could be done on a permission check or by getting allcourse admins for a course
    users = []
    #!TODO: Generate QC_Alert
    link =  payload.fetch(:link, '')
    course_id = payload.fetch(:course_id)
    #We will need to pass the users here in a futire version
    QcAlert.create(qc_rule_id: '', status: 'open', severity: 'medium', course_id: course_id, annotation: link)
    # for now lets just create new ones on every incoming message, we should later have a more sophisticated handling based on
    # a context_id or the data (data avail. per alert is pending in a featute branch)
    #!TODO: Notify all relevant Users
    event = {
        key: 'new_report',
        #receiver_id:user_id,
        payload: payload # for now we just pass the payload to the notification service
    }
    #each user do
    #!TODO set receiver id for each user
    Msgr.publish(event, to: 'xikolo.notification.new_report')
    #!TODO: Complete the new_report mail template in the notification service.
  end

end
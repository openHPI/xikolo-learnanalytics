#
#
#
# IT'S NOT ENOUGH TO SIMPLY ADD A ROUTE HERE,
# YOU NEED TO GO TO LIB/LANALYTICS/PROCESSING/PIPELINES/...
# AND REGISTER PIPELINES.
# OTHERWISE YOU MIGHT BE STUCK WONDERING WHY YOUR EVENT IS NOT
# WORKING
#
#
#
# ------------------- User Domain Entities -------------------
route 'xikolo.account.user.create', to: 'Lanalytics#create'
route 'xikolo.account.user.confirmed', to: 'Lanalytics#create'
route 'xikolo.account.user.update', to: 'Lanalytics#update'
route 'xikolo.account.user.destroy', to: 'Lanalytics#destroy'

# route 'xikolo.account.session.create', to: 'Lanalytics#create'


# ------------------- Course Domain Entities -------------------
route 'xikolo.course.course.create', to: 'Lanalytics#create'
route 'xikolo.course.course.update', to: 'Lanalytics#update'

route 'xikolo.course.course.destroy', to: 'QcAlert#destroy_course'

route 'xikolo.course.item.create', to: 'Lanalytics#create'
route 'xikolo.course.item.update', to: 'Lanalytics#update'
route 'xikolo.course.item.destroy', to: 'Lanalytics#destroy'

route 'xikolo.course.visit.create', to:  'Lanalytics#create'

route 'xikolo.course.enrollment.completed', to: 'Lanalytics#create'
route 'xikolo.course.enrollment.create', to: 'Lanalytics#create'
route 'xikolo.course.enrollment.update', to: 'Lanalytics#update'


# ------------------- Learning Room Domain Entities -------------------
route 'xikolo.collabspace.collab_space.create', to: 'Lanalytics#create'
route 'xikolo.collabspace.collab_space.update', to: 'Lanalytics#update'
route 'xikolo.collabspace.collab_space.destroy', to: 'Lanalytics#destroy'

route 'xikolo.collabspace.membership.create', to: 'Lanalytics#create'
route 'xikolo.collabspace.membership.update', to: 'Lanalytics#update'
route 'xikolo.collabspace.membership.destroy', to: 'Lanalytics#destroy'


# ------------------- Submissions Domain Entities -------------------
route 'xikolo.submission.submission.create', to: 'Lanalytics#create'


# ------------------- Pinboard Domain Entities -------------------
route 'xikolo.pinboard.question.create', to: 'Lanalytics#create'
route 'xikolo.pinboard.question.update', to: 'Lanalytics#update'
route 'xikolo.pinboard.answer.create', to: 'Lanalytics#create'
route 'xikolo.pinboard.answer.update', to: 'Lanalytics#update'
route 'xikolo.pinboard.comment.create', to: 'Lanalytics#create'
route 'xikolo.pinboard.comment.update', to: 'Lanalytics#update'
route 'xikolo.pinboard.subscription.create', to: 'Lanalytics#create'
route 'xikolo.pinboard.subscription.destroy', to: 'Lanalytics#destroy'
route 'xikolo.pinboard.watch.create', to: 'Lanalytics#create'
route 'xikolo.pinboard.watch.update', to: 'Lanalytics#update'
route 'xikolo.pinboard.answer.accept', to: 'Lanalytics#create'


# ------------------- Helpdesk Domain Entities -------------------
route 'xikolo.helpdesk.ticket.create', to: 'Lanalytics#create'


# ------------------- Web Events -------------------
route 'xikolo.web.exp_event.create', to: 'Lanalytics#handle_user_event'

route 'xikolo.web.referrer', to: 'Lanalytics#create'
route 'xikolo.web.tracking', to: 'Lanalytics#create'


# If you want to know how the routes look like, you can puts them with the following line:x
# puts @routes.inspect

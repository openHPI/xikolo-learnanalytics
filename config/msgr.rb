# ------------------- User Domain Entities -------------------
route 'xikolo.account.user.create', to: 'Lanalytics#create'
route 'xikolo.account.user.update', to: 'Lanalytics#update'
route 'xikolo.account.user.destroy', to: 'Lanalytics#destroy'

# route 'xikolo.account.session.create', to: 'Lanalytics#create'


# ------------------- Course Domain Entities -------------------
route 'xikolo.course.course.create', to: 'Lanalytics#create'
route 'xikolo.course.course.update', to: 'Lanalytics#update'
route 'xikolo.course.course.destroy', to: 'Lanalytics#destroy'

route 'xikolo.course.item.create', to: 'Lanalytics#create'
route 'xikolo.course.item.update', to: 'Lanalytics#update'
route 'xikolo.course.item.destroy', to: 'Lanalytics#destroy'

route 'xikolo.course.visit.create', to:  'Lanalytics#create'


# ------------------- Learning Room Domain Entities -------------------
route 'xikolo.learning_room.learning_room.create', to: 'Lanalytics#create'
route 'xikolo.learning_room.learning_room.update', to: 'Lanalytics#update'
route 'xikolo.learning_room.learning_room.destroy', to: 'Lanalytics#destroy'

route 'xikolo.learning_room.membership.create', to: 'Lanalytics#create'
route 'xikolo.learning_room.membership.update', to: 'Lanalytics#update'
route 'xikolo.learning_room.membership.destroy', to: 'Lanalytics#destroy'


# ------------------- Submissions Domain Entities -------------------
route 'xikolo.submission.submission.create', to: 'Lanalytics#create'


# ------------------- Pinboard Domain Entities -------------------
route 'xikolo.pinboard.question.create', to: 'Lanalytics#create'
route 'xikolo.pinboard.question.update', to: 'Lanalytics#update'
route 'xikolo.pinboard.subscription.create', to: 'Lanalytics#create'
route 'xikolo.pinboard.subscription.destroy', to: 'Lanalytics#destroy'


# ------------------- Web Events -------------------
route 'xikolo.web.event.create', to: 'Lanalytics#handle_user_event'

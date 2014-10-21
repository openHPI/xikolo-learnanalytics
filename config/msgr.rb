
# route 'lanalytics.domain.model', to: 'lanalytics#update'
# route 'lanalytics.event.stream', to: 'lanalytics#handle_user_event'

route 'xikolo.account.user.create', to: 'LanalyticsResource#create'
route 'xikolo.account.user.update', to: 'LanalyticsResource#update'
route 'xikolo.account.user.destroy', to: 'LanalyticsResource#destroy'

route 'xikolo.course.course.create', to: 'LanalyticsResource#create'
route 'xikolo.course.course.update', to: 'LanalyticsResource#update'
route 'xikolo.course.course.destroy', to: 'LanalyticsResource#destroy'

route 'xikolo.course.item.create', to: 'LanalyticsResource#create'
route 'xikolo.course.item.update', to: 'LanalyticsResource#update'
route 'xikolo.course.item.destroy', to: 'LanalyticsResource#destroy'

route 'xikolo.web.event.create', to: 'Lanalytics#handle_user_event'

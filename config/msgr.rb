route 'lanalytics.domain.model', to: 'lanalytics#update'
route 'lanalytics.event.stream', to: 'lanalytics#handle_user_event'

route 'xikolo.account.user.create', to: 'CreateResourceEvent#consume'
route 'xikolo.account.user.update', to: 'UpdateResourceEvent#consume'
route 'xikolo.account.user.destroy', to: 'DestroyResourceEvent#consume'

route 'xikolo.course.course.create', to: 'CreateResourceEvent#consume'
route 'xikolo.course.course.update', to: 'UpdateResourceEvent#consume'
route 'xikolo.course.course.destroy', to: 'DestroyResourceEvent#consume'

route 'xikolo.course.item.create', to: 'CreateResourceEvent#consume'
route 'xikolo.course.item.update', to: 'UpdateResourceEvent#consume'
route 'xikolo.course.item.destroy', to: 'DestroyResourceEvent#consume'
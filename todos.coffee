Tasks = new Mongo.Collection('tasks')


if Meteor.isServer
  Meteor.publish 'tasks', ->
    Tasks.find(
      $or: [
        { private: { $ne: true } }
        { owner: this.userId }
       ]
    )


if Meteor.isClient
  Meteor.subscribe 'tasks'


  Template.body.helpers
    tasks: ->
      if Session.get('hideCompleted')
        Tasks.find({ checked: { $ne: true } }, { sort: { createdAt: -1 } })
      else
        Tasks.find({}, { sort: { createdAt: -1 } })

    hideCompleted: ->
      Session.get('hideCompleted')

    incompleteCount: ->
      Tasks.find({ checked: { $ne: true }}).count()


  Template.body.events
    'submit .new-task': (event) ->
      text = event.target.text.value

      # Prevent default form submit
      #event.preventDefault

      Meteor.call('addTask', text)

      # Clear form
      event.target.text.value = ''

    'change .hide-completed input': (event) ->
      Session.set('hideCompleted', event.target.checked)


  Template.task.events
    'click .toggle-checked': ->
      Meteor.call('setChecked', this._id, not this.checked)

    'click .delete': ->
      Meteor.call('deleteTask', this._id)

    'click .toggle-private': ->
      Meteor.call('setPrivate', this._id, not this.private)


  Template.task.helpers
    isOwner: ->
      this.owner is Meteor.userId()

    relativeTime: ->
      moment(this.createdAt).fromNow()
      # below only works in 1.7+
      #      moment this.createdAt
      #      .fromNow

    Accounts.ui.config
      passwordSignupFields: 'USERNAME_ONLY'


Meteor.methods
  addTask: (text) ->
    throw new Meteor.Error('not-authorized') unless Meteor.userId()
    Tasks.insert(
      text:      text
      createdAt: new Date()
      owner:     Meteor.userId()
      username:  Meteor.user().username
      )
  deleteTask: (taskId) ->
    task = Tasks.findOne(taskId)
    throw new Meteor.Error('not-authorized') if task.private and task.owner isnt Meteor.userId()
    Tasks.remove(taskId)
  setChecked: (taskId, setChecked) ->
    task = Tasks.findOne(taskId)
    throw new Meteor.Error('not-authorized') if task.private and task.owner isnt Meteor.userId()
    Tasks.update(taskId, { $set: { checked: setChecked } })
  setPrivate: (taskId, setToPrivate) ->
    task = Tasks.findOne(taskId)
    throw new Meteor.Error('not-authorized') unless task.owner is Meteor.userId()
    Tasks.update(taskId, { $set: { private: setToPrivate } })


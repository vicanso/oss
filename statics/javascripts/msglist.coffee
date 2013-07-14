MsgModel = Backbone.Model.extend {
  defaults :
    name : ''
    status : ''
    desc : ''
}

MsgCollection = Backbone.Collection.extend {
  model : MsgModel
}

MsgListView = Backbone.View.extend {
  events :
    'click .title .minimize' : 'clickMinimize'
    'click .title .maximize' : 'clickMaximize'
  template : _.template '<li class="item <%= status %>" title="<%= desc %>"><%= name %></li>'
  clickMinimize : ->
    @minimize()
    @
  minimize : ->
    $el = @$el
    $el.find('.title .maximize').show()
    $el.find('.title .minimize').hide()
    $el.find('.items').hide()
    @
  clickMaximize : ->
    @maximize()
    @
  maximize : ->
    $el = @$el
    $el.find('.title .maximize').hide()
    $el.find('.title .minimize').show()
    $el.find('.items').show()
    @
  setTotal : ->
    # if @minimize
    @$el.find('.title .total').show().text "(#{@model.length})"
    @
  setStatus : (item, value, prevValue) ->
    index = @model.indexOf item
    if ~index
      itemObj = @$el.find('.items .item').eq index
      itemObj.removeClass(prevValue).addClass value
  setList : ->
    htmlArr = @model.map (item) =>
      @template item.toJSON()
    @$el.find('.items').html htmlArr.join ''
  remove : (index) ->
    @$el.find('.items .item').eq(index).remove()
  initialize : ->
    $el = @$el
    $el.addClass('msgList').html "<h4 class='title jtGrayGradient'><a href='javascript:;' class='minimize' title='最小化'>_</a><a href='javascript:;' class='maximize' title='最大化'></a>消息列表<span class='total'></span></h4><ul class='items'></ul>"
    @setList()
    @setTotal()
    if !@model.length
      @minimize()
    @listenTo @model, 'remove', (item, collection, options) =>
      @remove options.index
      @setTotal()
    @listenTo @model, 'change:status', (item, value) =>
      @setStatus item, value, item.previous 'status'
    @listenTo @model, 'add', (item) =>
      @setList()
      @setTotal()


}

window.MsgListView = MsgListView
window.MsgCollection = MsgCollection
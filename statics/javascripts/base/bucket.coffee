OSS = window.OSS ?= {}
OSS.Model ?= {}
OSS.Collection ?= {}
OSS.View ?= {}


OSS.Model.Bucket = Backbone.Model.extend {
  defaults : 
    name : ''
    active : ''
    className : ''
  initialize : ->
    @className = 'active' if @get 'active'
  idAttribute : 'name'
  urlRoot : '/bucket'

}

OSS.Collection.Bucket = Backbone.Collection.extend {
  model : OSS.Model.Bucket
  url : '/buckets'
}

OSS.View.Bucket = Backbone.View.extend {
  template : _.template '<div class="bucket <%= className %>" title="<%= name %>">' +
    '<div class="ops">' + 
      # '<a href="javascript:;" class="attr">属性</a>' +
      '<a href="javascript:;" class="delete">删除</a>' + 
    '</div>' +
    '<div class="arrowLeft"></div>' +
    '<div class="icon iBucket"></div>' +
    '<p class="name"><%= name %></p>' +
  '</div>'
  events :
    'click .bucket' : 'clickBucket'
    'click .bucket .ops .attr' : 'clickAttr'
    'click .bucket .ops .delete' : 'clickDelete'
  clickAttr : (e) ->
    e.preventDefault()
  clickDelete : (e) ->
    model = @model
    obj = $(e.currentTarget).closest '.bucket'
    index = obj.index()
    bucket = obj.find('.name').text()
    async.waterfall [
      (cbf) ->
        new JT.View.Alert {
          model : new JT.Model.Dialog {
            modal : true
            title : "确定删除bucket(#{bucket})?"
            content : "<p>请确定bucket(#{bucket})中无任何数据，非空的bucket无法删除。确定要删除当前的bucket吗？删除之后无法恢复！</p>"
            btns : 
              '确定' : ->
                cbf null, true
              '取消' : ->
                cbf null, false
          }
        }
      (confirm, cbf) ->
        if confirm
          $.ajax(
            url : "/deletebucket/#{bucket}"
            dataType : 'json'
          ).success (res) ->
            model.remove model.at index
    ]
    e.preventDefault()
  clickBucket : (e) ->
    target = $ e.target
    if !target.hasClass('attr') && !target.hasClass 'delete'
      obj = $ e.currentTarget
      index = obj.index '.bucket'
      @model.each (bucket, i) ->
        if i == index
          bucket.set 'active', 'active'
        else
          bucket.set 'active', ''
    @
  active : (bucket, value) ->
    index = @model.indexOf bucket
    obj = @$el.find('.bucket').eq index
    if value
      obj.addClass 'active'
    else
      obj.removeClass 'active'
    @
  item : (type, models, options) ->
    $el = @$el
    if !_.isArray models
      models = [models]
    if type == 'add'
      _.each models, (model) =>
        data = model.toJSON()
        $el.append @template data
    else if type == 'remove'
      $el.find('.bucket').eq(options.index).remove()
    @

  initialize : ->
    $el = @$el
    $el.addClass 'buckets'
    _.each 'add remove'.split(' '), (event) =>
      @listenTo @model, event, (models, collection, options) =>
        @item event, models, options
    @listenTo @model, 'change:active', (bucket, value) =>
      @active bucket, value
    @listenTo @model, 'reset', @render
    @render()
  render : ->
    self = @
    bucketHtmlArr = _.map @model.toJSON(), (data) ->
      self.template data
    @$el.html bucketHtmlArr.join ''
    @


}
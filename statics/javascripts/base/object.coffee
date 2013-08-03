OSS = window.OSS ?= {}
OSS.Model ?= {}
OSS.Collection ?= {}
OSS.View ?= {}


OSS.Model.ObjAttr = Backbone.Model.extend {
  defaults : 
    bucket : ''
    name : ''
  url : ->
    bucket = @get 'bucket'
    name = @get 'name'
    "/headobject/#{bucket}?obj=#{name}"
    # name = @get 'name'
    # if name.charAt(0) == '/'
    #   name = name.substring 1
    # bucketPath = @get('bucketPath').replace '/bucket/', '/headobject/'
    # "#{bucketPath}?obj=#{name}"
}


OSS.View.ObjAttr = Backbone.View.extend {
  deleteMeta : (e) ->
    obj = $ e.currentTarget
    obj.closest('.op').siblings('.value').find('.inputContainer input').val ''
  initialize : ->
    self = @
    @metaKeys = 'Last-Modified ETag Content-Type Content-Language Expires Cache-Control Content-Encoding Content-Disposition'.split ' '
    name = @model.get('name').split('/').pop()
    dialog = new JT.Model.Dialog {
      title : "Object属性(#{name})"
      modal : true
      content : @content()
      btns : 
        '保存' : ->
          self.saveMeta()
        '取消' : ->
    }
    @objAttrDialog = new JT.View.Dialog {
      model : dialog
      el : $('<div class="objAttrDialog" />').appendTo 'body'
    }
    @objAttrDialog.$el.on 'click', '.op .delete', (e) ->
      self.deleteMeta e
  saveMeta : ->
    model = @model
    dlgObj = @objAttrDialog.$el
    meta = 
      'Content-Type' : ''
      'Content-Language' : ''
      'Expires' : ''
      'Cache-Control' : ''
      'Content-Encoding' : ''
      'Content-Disposition' : ''
    dlgObj.find('tbody tr').each ->
      obj = $ @
      inputValue = obj.find('.inputContainer input').val()
      if inputValue?.length
        meta[obj.find('.param').text()] = inputValue
    model.save meta, {
      error : (model, res) ->
        console.dir 'save meta fail!'
    }

  content : ->
    viewKeys = @metaKeys
    trData = _.pick @model.toJSON(), viewKeys
    otherKeys = _.difference viewKeys, _.keys trData
    trHtmlArr = _.map trData, (value, key) ->
      trHtml = "<tr><td class='param'>#{key}</td>"
      if key != 'Last-Modified' && key != 'ETag' && key != 'Content-Type'
        trHtml += "<td class='value'><div class='inputContainer'><input type='text' value='#{value}' /></div></td><td class='op'><a href='javascript:;' class='delete'>删除</a></td>"
      else
        trHtml += "<td class='value'>#{value}</td><th class='op'></th>"
      trHtml += '</tr>'
    placeHolders = 
      'Cache-Control' : 'public, max-age=300'
      'Content-Language' : 'zh-CN'
      'Content-Encoding' : 'gzip'
      'Expires' : 'Tue, 03 Jun 2014 12:04:15 GMT'
      'Content-Disposition' : 'attachment; filename=test.txt'
    _.each otherKeys, (key) ->
      trHtml = "<tr><td class='param'>#{key}</td><td class='value'><div class='inputContainer'><input type='text' value='' placeholder='#{placeHolders[key]}' /></div></td><td class='op'></td></tr>"
      trHtmlArr.push trHtml
    '<table>' +
      '<thead><th class="param">参数</th><th class="value">值</th><th class="op">操作</th></thead>' +
      '<tbody>' +
        trHtmlArr.join('') +
      '</tbody>' +
    '</table>'
}

OSS.Model.Obj = Backbone.Model.extend {
  defaults : 
    name : ''
    size : ''
    type : ''
    sizeView : '-'
    typeView : ''
    lastModified : '-'
    op : '<a href="javascript:;" class="delete">删除</a>'
    _check : false
    _type : ''
  isNew : ->
    false
  set : (attributes, options) ->
    if attributes == '_check' && @get('name') == '../'
      return
    Backbone.Model.prototype.set.apply @, arguments
  url : ->
    path = @get('path') || ''
    "/deleteobject/#{@get('bucket')}?obj=#{path}#{@get('name')}"
    # @get('bucketPath') + '?prefix=' + @get('name')
  initialize : ->
    _type = @get '_type'
    name = @get 'name'
    # if !name
    #   @set 'name', '../'
    #   @set 'lastModified', '-'
    #   @set 'back', true
    #   _type = 'folder'
    #   @set '_type', _type
    @set 'className', _type
    if _type == 'folder'
      @set 'typeView', '文件夹'
    else
      itemUrl = window.encodeURI "http://#{@get('bucket')}.oss.aliyuncs.com/#{@get('path')}#{@get('name')}"
      @set 'op', '<a target="blank" href="' + itemUrl + '" class="download">下载</a><a href="javascript:;" class="delete">删除</a><a href="javascript:;" class="attr">属性</a>'

      sizeView = @get 'size'
      KB = 1024
      MB = 1024 * KB
      GB = 1024 * MB
      if sizeView > GB
        sizeView = "#{(sizeView / GB).toFixed(2)}GB"
      else if sizeView > MB
        sizeView = "#{(sizeView / MB).toFixed(2)}MB"
      else if sizeView > KB
        sizeView = "#{(sizeView / KB).toFixed(2)}KB"
      else
        sizeView = "#{sizeView}字节"
      @set 'sizeView', sizeView

      typeView = @get 'name'
      typeViewList = typeView.split '.'
      if typeViewList.length > 1
        @set 'typeView', typeViewList.pop()
      else
        @set 'typeView', ''

      @set 'lastModified', @get('lastModified').replace('.000Z', '').replace('T', ' ')
}

OSS.Collection.Obj = Backbone.Collection.extend {
  model : OSS.Model.Obj
  invertCheck : ->
    @each (itemModel) ->
      checked = !itemModel.get '_check'
      itemModel.set '_check', checked
}

OSS.View.Obj = Backbone.View.extend {
  template : _.template '<div class="head"><table>' + 
    '<thead><tr>' + 
      '<th class="check"></th>' +
      '<th class="name">文件名</th>' +
      '<th class="size">大小</th>' +
      '<th class="type">类型</th>' +
      '<th class="lastModified">最近修改时间</th>' +
      '<th class="op">操作</th>' +  
    '</tr></thead>' +
  '</table></div>' +
  '<div class="content"><table><tbody></tbody></table></div>'
  objTemplate : _.template '<tr class="item <%= className %>" data-key="<%= name %>">' +
    '<td class="check icon iBorder"></td>' +
    '<td class="name"><%= name %></td>' +
    '<td class="size"><%= sizeView %></td>' +
    '<td class="type"><%= typeView %></td>' +
    '<td class="lastModified"><%= lastModified %></td>' +
    '<td class="op"><%= op %></td>' +
  '</tr>'
  events : 
    'click .folder .name' : 'clickFolder'
    'click .op .attr' : 'clickAttr'
    'click .op .delete' : 'clickDelete'
    'click .item .check' : 'clickCheck'
  clickCheck : (e) ->
    item = $(e.currentTarget).closest '.item'
    itemModel = @model.at item.index()
    itemModel.set '_check', !itemModel.get '_check'

    # obj.toggleClass 'iOk iBorder'
    @
  clickFolder : (e) ->
    obj = $ e.currentTarget
    index = obj.closest('.item').index '.item'
    if @activeModel
      @activeModel.set 'active', false
    activeModel = @model.at index
    activeModel.set 'active', true
    @activeModel = activeModel
    @
  clickAttr : (e) ->
    obj = $ e.currentTarget
    index = obj.closest('.item').index '.item'
    if @viewAttrModel
      @viewAttrModel.set 'viewAttr', false
    viewAttrModel = @model.at index
    viewAttrModel.set 'viewAttr', true
    @viewAttrModel = viewAttrModel
    @
  clickDelete : (e) ->
    item = $(e.currentTarget).closest '.item'

    index = item.index '.item'
    deleteModel = @model.at index
    new JT.View.Alert {
      model : new JT.Model.Dialog {
        modal : true
        title : "删除#{deleteModel.get('name')}"
        content : '<p>删除该文件之后无法恢复，确定需要删除吗？</p>'
        btns : 
          '确定' : ->
            deleteModel.destroy {
              wait : true
              error : (model, res) ->
                console.dir 'error'
            }
          '取消' : ->
      }
    }
    @
  changeCheck : (itemModel, check) ->
    index = @model.indexOf itemModel
    if ~index
      checkObj = @$el.find('.content tbody .item').eq(index).find('.check').toggleClass 'iOk iBorder'
  remove : (index) ->
    @$el.find('.content tbody .item').eq(index).remove()
    @
  initialize : ->
    $el = @$el.addClass 'objectTableView'
    @render()
    @listenTo @model, 'reset', @initContent
    @listenTo @model, 'remove', (models, collection,  options) =>
      @remove options.index
    @listenTo @model, 'change:_check', (itemModel, value) =>
      @changeCheck itemModel, value
    @
  initContent : ->
    self = @
    objHtmlArr = @model.map (objModel) ->
      self.objTemplate objModel.toJSON()
    @$el.find('.content tbody').html objHtmlArr.join ''
    @$el.find('.content').scrollTop 0
    @
  render : ->
    self = @
    $el = @$el
    $el.html self.template()
    @initContent()
    @
}

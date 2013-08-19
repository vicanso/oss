

GlobalSetting = Backbone.Model.extend {
  key : ''
  value : ''
}

GlobalSettingList = Backbone.Collection.extend {
  model : GlobalSetting
  url : '/setting?type=global'
}
GlobalSettingView = Backbone.View.extend {
  initialize : ->
    @model.on 'reset', @render, @
  render : ->
    htmlArr = @model.map (item) ->
      key = item.get 'key'
      val = item.get 'value'
      desc = item.get 'desc'
      "<tr>
        <td>#{desc}</td>
        <td><input type='text' data-key='#{key}' value='#{val}' />
      </tr>"
    @$el.html htmlArr.join ''
}

HeaderSetting = Backbone.Model.extend {
  type : ''
  header : ''
  value : ''
}
HeaderSettingList = Backbone.Collection.extend {
  model : HeaderSetting
  url : '/setting?type=header'
}
HeaderSettingView = Backbone.View.extend {
  initialize : ->
    @model.on 'reset', @render, @
    @model.on 'add', @initItem, @
  initItem : (item) ->
    type = item.get('type') || ''
    header = item.get 'header'
    value = item.get('value') || ''
    trObj = $ "<tr>
      <td><input class='extType' type='text' placeholder='文件后缀，多种后缀用\",\"隔开' value='#{type}' /></td>
      <td><div class='headerSelect'></div></td>
      <td><input class='headerValue' type='text' value='#{value}' /></td>
    </tr>"
    headerData = _.map 'Content-Language Expires Cache-Control Content-Encoding Content-Disposition'.split(' '), (name, i) ->
      {
        key : name
        name : name
      }
    headerSelect = new JT.Collection.Select headerData
    new JT.View.Select {
      el : trObj.find '.headerSelect'
      tip : '选择响应头'
      model : headerSelect
      disabledInput : true
    }
    headerSelect.val header
    trObj.find('.jtSelect').css 'z-index', headerSelectIndex--
    @$el.append trObj
    @headerSelectList.push headerSelect
  val : ->
    result = @$el.find('tr').map (i, trObj) =>
      trObj = $ trObj
      type = trObj.find('.extType').val()
      header = @headerSelectList[i].val()[0]
      value = trObj.find('.headerValue').val()
      if type && header && value
        {
          type : type
          header : header
          value : value
        }
      else
        null
    _.compact result

  render : ->
    @$el.empty()
    @headerSelectList = []
    @model.each (item) =>
      @initItem item
}


headerSelectIndex = 99
# globalSetting = {}
Setting = Backbone.View.extend {
  events : 
    'click .resHeaderContainer .addRule' : 'clickAddRule'
    'click .btns .close' : 'clickClose'
    'click .globalContainer .btns .confirm' : 'clickGlobalSettingConfirm'
    'click .resHeaderContainer .btns .confirm' : 'clickResHeaderSettingConfirm'
  clickAddRule : ->
    @headerSettingList.add {}
    # @addRule()
    @
  clickGlobalSettingConfirm : ->
    result = {}
    self = @
    inputValues = @$el.find('.globalContainer input').each ->
      obj = $ @
      value = obj.val()
      key = obj.attr 'data-key'
      targetModel = self.globalSettingList.find (item) ->
        key == item.get 'key'
      if targetModel
        targetModel.set 'value', value
    postData = 
      setting : @globalSettingList.toJSON()
    $.post '/setting?type=global', postData
    @clickClose()
  clickResHeaderSettingConfirm : ->
    postData = 
      setting : @headerSettingView.val()
    $.post '/setting?type=header', postData
    @clickClose()
  show : ->
    @globalSettingList.fetch()
    @headerSettingList.fetch()
    @$el.show()
  clickClose : ->
    @$el.hide()
  # addRule : ->
  #   trObj = $ "<tr>
  #     <td><input type='text' placeholder='文件后缀，多种后缀用\",\"隔开' /></td>
  #     <td><div class='headerSelect'></div></td>
  #     <td><input type='text' /></td>
  #   </tr>"
  #   headerSelect = new JT.Collection.Select headerData
  #   new JT.View.Select {
  #     el : trObj.find '.headerSelect'
  #     tip : '选择响应头'
  #     model : headerSelect
  #     disabledInput : true
  #   }
  #   trObj.find('.jtSelect').css 'z-index', headerSelectIndex--
  #   @$el.find('.resHeaderContainer table tbody').append trObj
  #   @headerSelectList.push headerSelect
  #   @
  initTabs : ->
    contentList = @$el.find '.content'
    tabsCollection = new JT.Collection.Tabs [
      {
        title : '全局配置'
        content : contentList.eq(0).html()
      }
      {
        title : '响应头配置'
        content : contentList.eq(1).html()
      }
    ]
    settingTabs = new JT.View.Tabs {
      el : @$el
      model : tabsCollection
    }
    @headerSelectList = []
    @
  initialize : ->
    @initTabs()
    globalSettingList = new GlobalSettingList
    new GlobalSettingView {
      el : @$el.find '.globalContainer tbody'
      model : globalSettingList
    }
    # globalSettingList.fetch()
    @globalSettingList = globalSettingList


    headerSettingList = new HeaderSettingList
    @headerSettingView = new HeaderSettingView {
      el : @$el.find '.resHeaderContainer tbody'
      model : headerSettingList
    }
    # headerSettingList.fetch()
    @headerSettingList = headerSettingList

    # @addRule()
    @
}
  # show : ->
  #   settingTabs.$el.show()

# settingContainer = $ '#settingContainer'
# contentList = settingContainer.find '.content'
# tabsCollection = new JT.Collection.Tabs [
#   {
#     title : '全局配置'
#     content : contentList.eq(0).html()
#   }
#   {
#     title : '响应头配置'
#     content : contentList.eq(1).html()
#   }
# ]
# settingTabs = new JT.View.Tabs {
#   el : $ '#settingContainer'
#   model : tabsCollection
# }
# settingTabs.$el.find('.resHeaderContainer .headerSelect').each ->
#   headerSelect = new JT.Collection.Select headerData
#   new JT.View.Select {
#     el : @
#     tip : '选择响应头'
#     model : headerSelect
#     disabledInput : true
#   }

window.SETTING = new Setting {
  el : $ '#settingContainer'
}
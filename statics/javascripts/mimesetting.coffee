window.MimeSetting = 
  openDlg : (el, resHeaders, staticMimes, cbf) ->
    self = @
    $el = $ el
    if _.isFunction staticMimes
      cbf = staticMimes
      staticMimes = null
    html = ''
    if staticMimes
      html = '<div class="mimeTypeList"></div>'
    settingDialog = new JT.Model.Dialog {
      title : 'HTTP响应头配置'
      content : html + self._getResHeaderContainerHtml resHeaders
      modal : true
      btns : 
        '确定' : ->
          if mimeTypeCollection
            mimes = mimeTypeCollection.val()
          result = {}
          $el.find('tbody .item').each ->
            obj = $ @
            value = obj.find('.value input').val()
            if value
              result[obj.find('.name').text()] = value
          cbf null, {
            mimes : mimes
            headers : result
          }
        '取消' : ->
            cbf null
    }
    settingDialogView = new JT.View.Dialog {
      el : $el
      model : settingDialog
    }
    if staticMimes
      mimeTypeCollection = self._initSelect $el.find('.mimeTypeList'), staticMimes
    @
  _initSelect : (el, staticMimes) ->
    mimeTypeCollectionData = _.map staticMimes, (mime) ->
      {
        key : mime
        name : mime
      }
    mimeTypeCollection = new JT.Collection.Select mimeTypeCollectionData
    mimeTypeView = new JT.View.Select {
      el : el
      tips : '选择需要配置的文件类型'
      model : mimeTypeCollection
      multi : true
    }
    mimeTypeCollection
  _getResHeaderContainerHtml : (resHeaders) ->
    htmlArr = _.map resHeaders, (header) ->
      "<tr class='item'><td class='name'>#{header.name}</td><td class='value'><input type='text' placeholder='#{header.tip}' /></td></tr>"
    "<div class='resHeadersContainer'><p class='tip'>请填写需要配置的属性：</p><table><tbody>#{htmlArr.join('')}</tbody></table></div>"
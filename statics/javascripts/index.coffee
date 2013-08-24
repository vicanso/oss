if window.location.search == '?type=node-webkit'
  window.APP_MODE = 'node-webkit'
jQuery ($) ->
  _ = window._
  keyId = $.cookie 'keyId'
  keySecret = $.cookie 'keySecret'
  loginDlg = new JT.View.Dialog {
    el : $ '#loginDialog'
    model : new JT.Model.Dialog {
      title : '登录OSS'
      content : "<div class='inputItem'><span class='name'>Key ID:</span><input class='keyId' type='text' placeholder='请输入OSS KEY ID' value='#{keyId || ""}' /></div>
      <div class='inputItem'><span class='name'>Key Secret:</span><input class='keySecret' type='text' placeholder='请输入OSS KEY SECRET' value='#{keySecret || ""}'/></div>
      "
      modal : true
      destroyOnClose : false
      btns : 
        '登录' : (dlg) ->
          keyId = dlg.find('.keyId').val().trim()
          keySecret = dlg.find('.keySecret').val().trim()
          if keyId && keySecret
            $.cookie 'keyId', keyId, {expires : 365}
            $.cookie 'keySecret', keySecret, {expires : 365}
            $.ajax({
              url : '/login'
              type : 'post'
              data : 
                keyId : keyId
                keySecret : keySecret
            }).done(() ->
              window.location.reload()
            ).fail () ->

        '取消' : ->
    }
  }
  loginDlg.close()
  # loginDlg.open()

  do ->
    msgList = new MsgCollection
    tmp = new MsgListView {
      model : msgList
      el : $ '#msgListContainer'
    }
    window.MSG_LIST = msgList
    # msgList.add [
    #   {
    #     id : '111'
    #     name : '测试1'
    #     status : 'doing'
    #     desc : '上传文件....'
    #   }
    #   {
    #     id : '112'
    #     name : '测试2'
    #     status : 'doing'
    #     desc : '上传文件....'
    #   }
    #   {
    #     id : '113'
    #     name : '测试3'
    #     desc : '上传文件....'
    #   }
    #   {
    #     id : '114'
    #     name : '测试4'
    #     desc : '上传文件....'
    #   }
    #   {
    #     id : '115'
    #     name : '测试5'
    #     desc : '上传文件....'
    #   }
    #   {
    #     id : '116'
    #     name : '测试6'
    #     desc : '上传文件....'
    #   }
    #   {
    #     id : '117'
    #     name : '测试7'
    #     desc : '上传文件....'
    #   }
    # ]
    # tmp.maximize()
    $(document).ajaxError (e, res) ->
      if res.status == 401
        loginDlg.open()
do ->
  urlPrefix = ''
  if window.location.host != 'oss.vicanso.com'
    urlPrefix = '/oss'

  ajax = $.ajax
  $.ajax = _.wrap $.ajax, (func, options) ->
    options.retry = ->
      func options
    func options

  $('#loadingMask').on 'click', '.bgExec', ->
    $('#loadingMask').hide()

    .ajaxSend( handler(event, jqXHR, ajaxOptions) )
  $(document).ajaxStart( ->
    $('#loadingMask').show()
  ).ajaxSend((e, res, options) ->
    options.headers ?= {}
    # options.headers['v-nocache'] = true
  ).ajaxComplete (e, res, options) ->
    if res.status == 500
      content = res.responseJSON?.msg || res.responseText
      new JT.View.Alert {
        model : new JT.Model.Dialog {
          modal : true
          title : "错误提示"
          content : content || '<p>请求数据失败！</p>'
          btns : 
            '重试' : ->
              options.retry();
            '关闭' : ->

        }
      }
    _.defer ->
      $('#loadingMask').hide()
  _.delay ->
    $(window).trigger 'resize'
  , 100


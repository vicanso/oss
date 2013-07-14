jQuery ($) ->
  _ = window._
  loginDlg = new JT.View.Dialog {
    el : $ '#loginDialog'
    model : new JT.Model.Dialog {
      title : '登录OSS'
      content : "<div class='inputItem'><span class='name'>Key ID:</span><input class='keyId' type='text' value='Z8pQTAkCNNDAOPjt' /></div>
      <div class='inputItem'><span class='name'>Key Secret:</span><input class='keySecret' type='text' value='z014NFAjKNLpvP07TSACKjNDgQDsqS'/></div>
      "
      modal : true
      destroyOnClose : false
      btns : 
        '登录' : (dlg) ->
          keyId = dlg.find('.keyId').val()
          keySecret = dlg.find('.keySecret').val()
          if keyId && keySecret
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
    new MsgListView {
      model : msgList
      el : $ '#msgListContainer'
    }
    window.MSG_LIST = msgList
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
  # $.ajax = (options) ->
  #   options.retry = ->
  #     ajax options
  #   ajax options

  $('#loadingMask').on 'click', '.bgExec', ->
    $('#loadingMask').hide()
  $(document).ajaxStart( ->
    # if setting.dataType != 'script'
    #   setting.url = urlPrefix + setting.url
    $('#loadingMask').show()
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
    $('#loadingMask').hide()
  _.delay ->
    $(window).trigger 'resize'
  , 100
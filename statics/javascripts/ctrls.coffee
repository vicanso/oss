jQuery ($) ->
  Ctrls = Backbone.View.extend {
    events : 
      'click .nextPage' : 'nextPage'
      'click .prevPage' : 'prevPage'
      'click .invertSelection' : 'invertSelection'
      'click .attrGroup' : 'attrGroup'
      'click .remove' : 'remove'
    nextPage : ->
      btn = @$el.find '.nextPage'
      if btn.hasClass 'disabled'
        return
      window.OSS_FILTER.nextPage()
    prevPage : ->
      btn = @$el.find '.prevPage'
      if btn.hasClass 'disabled'
        return
      window.OSS_FILTER.prevPage()
    invertSelection : ->
      window.OBJ_COLLECTION.invertCheck()

    attrGroup : ->
      resHeaders = [
        {
          name : 'Content-Language'
          tip : 'zh-CN'
        }
        {
          name : 'Expires'
          tip : 'Tue, 04 Jun 2013 02:45:23 GMT'
        }
        {
          name : 'Cache-Control'
          tip : 'max-age=300'
        }
        {
          name : 'Content-Encoding'
          tip : 'gzip'
        }
        {
          name : 'Content-Disposition'
          tip : 'attachment; filename=1359517123_33_937.gif'
        }
      ]
      MimeSetting.openDlg $('<div class="mimeSetting" />').appendTo('body'), resHeaders, (err, result) =>
        if !result
          return
        objs = @getCheckObjs true
        if objs.length
          $.ajax({
            url : "/headobjects/#{window.OSS_FILTER.get('bucket')}"
            type : 'post'
            data : 
              headers : result.headers
              objs : objs
          }).done((res) ->
            window.OSS_FILTER.trigger 'refresh', window.OSS_FILTER
          ).fail (res) ->
            console.dir 'headobjects fail!'
    getCheckObjs : (filterFolder) ->
      path = window.OSS_FILTER.get 'path'
      bucket = window.OSS_FILTER.get 'bucket'
      objs = _.compact window.OBJ_COLLECTION.map (objModel) ->
        if objModel.get '_check'
          if !filterFolder
            path + objModel.get 'name'
          else if objModel.get('_type') != 'folder'
            path + objModel.get 'name'
        else
          ''
      objs
    remove : ->
      userSelectCbf = (cbf) ->
        new JT.View.Alert {
          model : new JT.Model.Dialog {
            modal : true
            title : "确定要删除这些文件"
            content : '<p>删除该文件之后无法恢复，确定需要删除吗？</p>'
            btns : 
              '确定' : ->
                cbf null, true
              '取消' : ->
                cbf null, false
          }
        }
      getObjs = (comfirm, cbf) =>
        if comfirm
          objs = @getCheckObjs()
          cbf null, objs
        else
          cbf null
      async.waterfall [
        userSelectCbf
        getObjs
      ], (err, objs) =>
        if objs.length
          $.ajax({
            url : "/deleteobjects/#{window.OSS_FILTER.get('bucket')}"
            type : 'post'
            data :
              objs : objs
          }).done((res) =>
            window.OSS_FILTER.trigger 'refresh', window.OSS_FILTER
          ).fail (res) ->
            console.dir 'deleteobjects fail!'

    showPageBtn : (selector, hidden) ->
      pageBtn = @$el.find selector
      if hidden
        pageBtn.addClass 'disabled'
      else
        pageBtn.removeClass 'disabled'
    setCheckedStatus : ->
      btns = @$el.find '.remove, .attrGroup'
      checkObj = window.OBJ_COLLECTION.find (obj) ->
        obj.get '_check'
      if checkObj
        btns.removeClass 'disabled'
      else
        btns.addClass 'disabled'
      @hasChecked = false
      @
    initialize : ->
      @listenTo window.OSS_FILTER, 'change:firstPage', (model, value) =>
        @showPageBtn '.prevPage', value
      @listenTo window.OSS_FILTER, 'change:lastPage', (model, value) =>
        @showPageBtn '.nextPage', value
      setCheckedStatus = _.debounce =>
        @setCheckedStatus()
      , 50
      window.OBJ_COLLECTION.on 'change:_check', (model, value) =>
        setCheckedStatus()
        # btns = @$el.find '.remove, .attrGroup'
        # if hasChecked
        #   btns.removeClass 'disabled'
        # else
        #   btns.addClass 'disabled'

  }

  new Ctrls {
    el : '#objectTableContainer .ctrlsContainer'
  }
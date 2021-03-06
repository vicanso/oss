jQuery ($) ->
  window.addEventListener 'message', (e) ->
    data = e.data
    console.dir data
    if data.type == 'putObjectFromFileList'
      objCtrls.setUploadFileStatus data.file, data.status
    else if data.type == 'uploadLargeFile'
      objCtrls.setUploadLargeFile data.file, data.complete, data.total
  ObjCtrls = Backbone.View.extend {
    events : 
      'click .btns .createFolder' : 'createFolder'
      'click .btns .refresh' : 'refresh'
      'click .btns .search' : 'search'
      'keyup .keyword' : 'userInput'
    userInput : (e) ->
      if e.keyCode == 0x0d
        @search()
    search : ->
      keyword = @$el.find('.searchContainer .keyword').val()
      window.OSS_FILTER.set 'markers', []
      window.OSS_FILTER.set 'keyword', keyword
      window.OSS_FILTER.trigger 'getdata', window.OSS_FILTER
      # window.OSS_PATH.set 'keyword', keyword
    initSearchEvent : ->
      keywordObj = @$el.find '.keyword'
      @$el.find('.advancedSearch :radio').change ->
        obj = $ @
        name = obj.attr 'name'
        value = obj.attr 'data-value'
        placeholder = obj.attr 'data-placeholder'
        keywordObj.attr 'placeholder', placeholder
        if name == 'path'
          window.OSS_FILTER.set 'delimiter', value
        else
          window.OSS_FILTER.set 'searchType', value
    refresh : ->
      window.OSS_FILTER.trigger 'refresh', window.OSS_FILTER
    createFolder : ->
      async.waterfall [
        (cbf) ->
          el = $ '<div class="jtAlertDlg" style="width:600px;margin-left:-300px;" />'
          new JT.View.Alert {
            el : el.appendTo 'body'
            model : new JT.Model.Dialog {
              modal : true
              title : '创建新文件夹'
              content : "<div class='createFolderContainer'>
                <div>
                  <span>文件夹：</span>
                  <input type='text' class='folderName' placeholder='请输入要创建的文件夹名' />
                </div>
                <div class='rules'><h2>文件命名规范：</h2>
                  <ul>
                    <li>只能包含字母，数字，中文，下划线（_）和短横线（-）,小数点（.）</li>
                    <li>只能以字母、数字或者中文开头</li>
                    <li>文件夹的长度限制在1-254之间</li>
                    <li>Object总长度必须在1-1023之间</li>
                  </ul>
                </div>
              </div>"
              btns :
                '确定' : (dlg) ->
                  folderName = dlg.find('.folderName').val()
                  cbf null, folderName
                '取消' : ->
                  cbf null, null

            }
          }
          el.find('.folderName').focus().on 'keyup', (e) ->
            if e.keyCode == 0x0d
              el.find('.btns .btn:first').click()
        (folderName, cbf) ->
          if folderName
            path = window.OSS_FILTER.get('path')
            path = path + folderName
            url = "/createfolder/#{window.OSS_FILTER.get('bucket')}?path=#{path}"
            $.get(url).done ->
              window.OSS_FILTER.trigger 'refresh', window.OSS_FILTER
      ]
    setUploadStatus : (enabled) ->
      uploadSwfContainer = @$el.find '.uploadBtn .uploadSwfContainer'
      if enabled
        uploadSwfContainer.css('visibility', 'visible').siblings('.jtBtn').removeClass 'disabled'
      else
        uploadSwfContainer.css('visibility', 'hidden').siblings('.jtBtn').addClass 'disabled'
    putFiles : (files) ->
      window.PUT_FILES_PROGRESS = (file, status) ->
        console.dir arguments
      _.each files.split(';'), (file) ->
        fileName = file
        index = file.indexOf '/'
        if ~index
          fileName = file.substring index + 1
        window.MSG_LIST.add {
          id : file
          name : fileName
          desc : "上传文件:#{file}"
        }
      $.ajax {
        type : 'post'
        url : '/putfiles'
        data : 
          bucket : window.OSS_FILTER.get 'bucket'
          path : window.OSS_FILTER.get 'path'
          files : files
      }
    setUploadFileStatus : (id, status) ->
     doingModel = window.MSG_LIST.find (model) ->
        id == model.get 'id'
      if doingModel
        if status == 'complete'
          window.MSG_LIST.remove doingModel
        else
          doingModel.set 'status', status
    setUploadLargeFile : (id, complete, total) ->
      doingModel = window.MSG_LIST.find (model) ->
        id == model.get 'id'
      if doingModel
        doingModel.set 'progress', Math.floor 100 * complete / total
    setUploadPath : (uploadPath) ->
      $.ajax({
        url : "/uploadpath/#{window.encodeURIComponent(uploadPath)}"
      }).success (data) =>
        @putFiles data.join ';'
    initialize : ->
      self = @
      window.OSS_FILTER.on 'change:keyword', (model) =>
        keyword = model.get 'keyword'
        keywordObj = @$el.find '.searchContainer .keyword' 
        if keyword != keywordObj.val()
          keywordObj.val keyword
      if window.APP_MODE == 'node-webkit'
        uploadPathChooseBtn = @$el.find '#uploadPathInput'
        @$el.find('.btns .uploadPath .jtBtn').click =>
          uploadPathChooseBtn.click()
        @$el.find('.btns .uploadBtn .uploadSwfContainer').html('<input type="file" multiple />').hide()
        fileChooseBtn = @$el.find '.btns .uploadBtn .uploadSwfContainer input'
        fileChooseBtn.on 'change', ->
          self.putFiles @value
        uploadPathChooseBtn.on 'change', ->
          self.setUploadPath @value
        @$el.find('.btns .uploadBtn .jtBtn').click =>
          fileChooseBtn.click()
      else
        @swfUpload = initSwfupload {
          file_queued_handler : (info) ->
            window.MSG_LIST.add {
              id : info.id
              name : info.name
              desc : "上传文件:#{info.name}"
            }
          # file_queue_error_handler : fileQueueError
          file_dialog_complete_handler : (numFilesSelected) ->
            if numFilesSelected
              self.swfUpload.setPostParams {
                bucket : window.OSS_FILTER.get 'bucket'
                path : window.OSS_FILTER.get 'path'
              }
              this.startUpload()
              self.setUploadStatus false
          upload_start_handler : (info) =>
            id = info.id
            @setUploadFileStatus id, 'doing'
          # upload_progress_handler : uploadProgress
          # upload_error_handler : uploadError
          # upload_success_handler : uploadSuccess
          upload_complete_handler : (info) =>
            id = info.id
            @setUploadFileStatus id, 'complete'
          queue_complete_handler : =>
            @setUploadStatus true
            console.dir 'all complete'
        }

      @initSearchEvent()
  }
  objCtrls = new ObjCtrls {
    el : $ '.objCtrlsContainer'
  }

initSwfupload = (options) ->
  setting = {
    flash_url : '/static/swfupload/swfupload.swf'
    upload_url : '/upload'
    custom_settings : 
      progressTarget : "fsUploadProgress"
      cancelButtonId : "btnCancel"
    button_placeholder_id : 'uploadBtn'
    button_width : '56'
    button_height : '30'
    button_text : '上传'
    file_size_limit : "100 MB"
    file_types : "*.*"
    file_types_description : "All Files"
    file_upload_limit : 2000
    file_queue_limit : 0
    debug : false
  }
  swfu = new SWFUpload _.extend setting, options
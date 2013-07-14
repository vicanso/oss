jQuery ($) ->
  LeftContainer = Backbone.View.extend {
    events : 
      'click .opContainer .createBucket' : 'createBucket'
      'click .opContainer .setting' : 'setting'
    ###*
     * resize 浏览器窗口大小变化时调整
     * @return {[type]} [description]
    ###
    resize : ->
      height = $(window).height()
      @$el.find('.bucketsContainer').height height - @resizeOffsetHeight
      @
    createBucket : ->
      createBucketDlg = new JT.View.Alert {
        model : new JT.Model.Dialog {
          title : '创建bucket'
          content : '<p>请输入bucket的名字：<input type="text" class="bucket" /></p>'
          modal : true
          btns : 
            '确定' : ($el) =>
              bucket = $el.find('.bucket').val()
              $.ajax({
                url : "/createbucket/#{bucket}"
              }).done( (res) =>
                @bucketList.add {
                  name : bucket
                }
              )
            '取消' : ->

        }
      }
      createBucketDlg.$el.find('.bucket').focus().on 'keyup', (e) ->
        if e.keyCode == 0x0d
          createBucketDlg.$el.find('.btns .btn:first').click()
      @
    setting : ->
      window.SETTING.show()
      @
    ###*
     * showBucketsView 显示bucket列表
     * @return {[type]} [description]
    ###
    showBucketsView : ->
      bucketList = @bucketList
      $el = @$el
      if !bucketList
        bucketList = new OSS.Collection.Bucket
        bucketView = new OSS.View.Bucket {
          el : $el.find '.bucketsContainer'
          model : bucketList
        }
        @listenTo bucketList, 'change:active', (bucket, active) =>
          if active
            @setBucketActive bucket
        @bucketList = bucketList
      bucketList.fetch {
        success : (collection, res, options) ->
          # collection.reset res
          collection.at(0).set 'active', true
      }
      @bucketList = bucketList
      @
    setBucketActive : (bucket) ->
      @activeBucket = bucket
      window.OSS_FILTER.set 'bucket', bucket.get 'name'
      @
    # changePath : (pathName = '') ->
    #   ossPath = window.OSS_PATH
    #   console.dir 'changePath'
    #   @
    initialize : ->
      resize = =>
        @resize()
      $(window).resize _.debounce resize, 200
      @resizeOffsetHeight = @$el.find('.opContainer').outerHeight() + @$el.children('.title').outerHeight()
      @showBucketsView()
      @

  }

  new LeftContainer {
    el : $ '#leftContainer'
  }
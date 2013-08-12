jQuery ($) ->
  LeftContainer = Backbone.View.extend {
    events : 
      'click .opContainer .createBucket' : 'createBucket'
      'click .opContainer .setting' : 'setting'
      'click .bucketListDown' : 'bucketListDown'
      'click .bucketListUp' : 'bucketListUp'
    bucketListUp : ->
      @setBucketListOffset 'up'
      # if @scrollHeight > @bucketsContainerHeight
      #   firstBucket = @$el.find '.bucketsContainer .bucket:first'
      #   firstBucket.css 'margin-top', 0
      #   @$el.find('.bucketListDown').addClass 'active'
      #   @$el.find('.bucketListUp').removeClass 'active'
    bucketListDown : ->
      @setBucketListOffset 'down'
      # firstBucket = @$el.find '.bucketsContainer .bucket:first'
      # currentMarginTop = window.parseInt firstBucket.css 'margin-top'
      # minMarginTop = @bucketsContainerHeight - @scrollHeight
      # marginTop = Math.max minMarginTop, currentMarginTop - @bucketsContainerHeight
      # firstBucket.css 'margin-top', marginTop
      # @$el.find('.bucketListDown').removeClass 'active'
      # @$el.find('.bucketListUp').addClass 'active'
    setBucketListOffset : (type)->
      firstBucket = @$el.find '.bucketsContainer .bucket:first'
      currentMarginTop = window.parseInt firstBucket.css 'margin-top'
      minMarginTop = @bucketsContainerHeight - @scrollHeight
      if type == 'down'
        marginTop = Math.max minMarginTop, currentMarginTop - @bucketsContainerHeight
      else
        marginTop = Math.min 0, currentMarginTop + @bucketsContainerHeight
      firstBucket.css 'margin-top', marginTop
      if type == 'down'
        if marginTop == minMarginTop
          @$el.find('.bucketListDown').removeClass 'active'
        @$el.find('.bucketListUp').addClass 'active'
      else
        @$el.find('.bucketListDown').addClass 'active'
        if !marginTop
          @$el.find('.bucketListUp').removeClass 'active'
    ###*
     * resize 浏览器窗口大小变化时调整
     * @return {[type]} [description]
    ###
    resize : ->
      height = $(window).height()
      @bucketsContainerHeight = height - @resizeOffsetHeight
      bucketsContainer = @$el.find '.bucketsContainer'
      bucketsContainer.height @bucketsContainerHeight
      @scrollHeight = bucketsContainer.prop 'scrollHeight'

      if @scrollHeight > @bucketsContainerHeight
        @$el.find('.bucketListDown').addClass('active').css 'top', @bucketsContainerHeight
      else
        @$el.find('.bucketsContainer .bucket:first').css 'margin-top', 0
        @$el.find('.bucketListDown, .bucketListUp').removeClass 'active'
      @
    createBucket : ->
      competenceCollection = new JT.Collection.Select [
        {
          key : 'public-read-write'
          name : '公共读写'
        }
        {
          key : 'public-read'
          name : '公共读'
        }
        {
          key : 'private'
          name : '私有读写'
        }
      ]
      competenceView = new JT.View.Select {
        el : $('<div style="float:right;" />')
        tips : 'Bucket权限'
        model : competenceCollection
      }
      createBucketDlg = new JT.View.Alert {
        model : new JT.Model.Dialog {
          title : '创建bucket'
          content : "<p>请输入bucket的名字：<input type='text' class='bucket' /></p>
            <div class='competence' style='margin-top:10px;width:290px;line-height:30px;'>请选择bucket的权限：</div>
            "
          modal : true
          btns : 
            '确定' : ($el) =>
              bucket = $el.find('.bucket').val()
              if bucket
                url = "/createbucket/#{bucket}"
                selectValue = competenceCollection.val()[0]
                if selectValue
                  url += "/#{selectValue}"
                $.ajax({
                  url : url
                }).done( (res) =>
                  @bucketList.add {
                    name : bucket
                  }
                )
              else
                createBucketDlg.$el.find('.bucket').focus()
                false
            '取消' : ->
        }
      }
      competenceView.$el.prependTo createBucketDlg.$el.find('.competence') 
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
        @listenTo bucketList, 'add remove', =>
          _.delay =>
            @resize()
          , 100
        @bucketList = bucketList
      bucketList.fetch {
        success : (collection, res, options) =>
          # collection.reset res
          collection.at(0).set 'active', true
          @resize()
      }
      @bucketList = bucketList
      @
    setBucketActive : (bucket) ->
      @activeBucket = bucket
      window.OSS_FILTER.set 'bucket', bucket.get 'name'
      window.OSS_FILTER.set 'path', ''
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
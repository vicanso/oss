jQuery ($) ->
  ossFilter = window.OSS_FILTER
  objCollection = new OSS.Collection.Obj
  
  new OSS.View.Obj {
    el : $ '#objectTableContainer .objectTableView'
    model : objCollection
    # changePath : (folder) ->
    #   console.dir 'changePath'
    #   # self.changePath self.getAbsolutePath folder
    # getAttr : (objName) ->
    #   console.dir 'getAttr'
    #   # self.getAttr self.getAbsolutePath objName
    # delete : (objName) ->
    #   console.dir 'delete'
    #   # self.delete self.getAbsolutePath objName
  }
  resize = ->
    height = $(window).height()
    offset = 150
    if window.MSG_LIST.status == 'maximize'
      offset += 90
    else
      offset += 20
    $('#objectTableContainer .objectTableView .content').height height - offset
  $(window).on 'resize', _.debounce resize, 200
  # resize()
  window.OBJ_COLLECTION = objCollection

 

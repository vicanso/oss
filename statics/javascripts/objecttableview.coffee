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
    $('#objectTableContainer .objectTableView .content').height height - 150
  $(window).on 'resize', _.debounce resize, 200
  # resize()
  window.OBJ_COLLECTION = objCollection

 

ossFilter = new OSS.Model.Filter
window.OSS_FILTER = ossFilter
jQuery ($) ->
  pathsObj = $('#objectTableContainer .paths').on 'click', '.path', ->
    obj = $ @
    if !obj.hasClass 'active'
      ossFilter.set 'path', obj.attr 'data-path'
  setMarkers = (next) ->
    if !next
      ossFilter.set 'lastPage', true
      return
    markers = ossFilter.get('markers') || []
    if markers.length
      ossFilter.set 'firstPage', false
    else
      ossFilter.set 'firstPage', true
    markers.push next
    ossFilter.set 'markers', markers
    ossFilter.set 'lastPage', false
  setPaths = ->
    paths = _.compact ossFilter.get('path').split '/'
    paths.unshift ossFilter.get 'bucket'
    lastPath = paths.pop()
    dataPath = null
    pathHtmlArr = _.map paths, (currentPath, i) ->
      if dataPath == null
        dataPath = ''
      else
        dataPath += "#{currentPath}/"
      '<a href="javascript:;" class="path" data-path="' + dataPath + '">' + currentPath + '</a>'
    pathHtmlArr.push '<a href="javascript:;" class="path active">' + lastPath + '</a>'
    pathsObj.html "当前位置：#{pathHtmlArr.join('')}"

  ossFilter.on 'change:path change:bucket', (model) ->
    model.reset()
    model.trigger 'getdata', model
    setPaths()
  
    
  ossFilter.on 'refresh', (model) ->
    markers = model.get 'markers'
    if markers
      markers.pop()
      model.set 'markers', markers
    model.trigger 'getdata', model
  ossFilter.on 'getdata', (model) ->
    model.fetch {
      success : (model, res) ->
        if res
          path = model.get 'path'
          bucket = model.get 'bucket'
          items = _.map res.items, (item) ->
            item.bucket = bucket
            item.path = path
            item.name = item.name.substring path.length
            if item.name
              item
          if path
            items.unshift {
              name : '../'
              lastModified : '-'
              back : true
              op : '-'
              _type : 'folder'
            }
          window.OBJ_COLLECTION.reset _.compact items
          setMarkers res.next
      error : ->
        window.OBJ_COLLECTION.reset []
        console.dir 'oss path fetch fail!'
    }
  ossFilter.listenTo window.OBJ_COLLECTION, 'change:active', (objModel, value) ->
    if value && objModel.get('_type') == 'folder'
      path = ossFilter.get 'path'
      if objModel.get 'back'
        paths = _.compact path.split '/'
        paths.pop()
        if paths.length
          ossFilter.set 'path', "#{paths.join('/')}/"
        else
          ossFilter.set 'path', ''
      else
        if path
          path += "#{objModel.get('name')}"
        else
          path = objModel.get 'name'
        ossFilter.set 'path', path

OSS = window.OSS ?= {}
OSS.Model ?= {}
OSS.Collection ?= {}
OSS.View ?= {}

OSS.Model.Filter = Backbone.Model.extend {
  defaults : 
    path : ''
    bucket : ''
    delimiter : '/'
  url : ->
    url = "/objects/#{@get('bucket')}"
    params = []
    path = @get 'path'
    prefix = @get 'prefix'
    keyword = @get 'keyword'
    if path
      if prefix
        path += prefix
      params.push "prefix=#{path}"
    else if prefix
      params.push "prefix=#{prefix}"
    if keyword
    	params.push "keyword=#{keyword}"
    _.each 'delimiter searchType'.split(' '), (type) =>
      value = @get type
      if value
        params.push "#{type}=#{value}"
    markers = @get 'markers'
    if markers?.length
      params.push "marker=#{_.last(markers)}"
    if params.length
      url += "?#{params.join('&')}"
    url
  reset : ->
    @set 'prefix', ''
    @set 'keyword', ''
    @set 'markers', ''
    @set 'delimiter', '/'

  nextPage : ->
    @trigger 'getdata', @
  prevPage : ->
    markers = @get 'markers'
    markers.pop()
    if !@get 'lastPage'
      markers.pop()
    @set 'markers', markers
    @trigger 'getdata', @
}
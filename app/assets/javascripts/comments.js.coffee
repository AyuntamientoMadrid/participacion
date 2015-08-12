App.Comments =

  add_response: (parent_id, response_html) ->
    $(response_html).insertAfter($("#js-comment-form-#{parent_id}"))

  reset_and_hide_form: (id) ->
    form  = $("#js-comment-form-#{id} form")
    input = form.find("textarea")
    input.val('')
    form.hide()

  reset_form: (id) ->
    input = $("#js-comment-form-#{id} form textarea")
    input.val('')

  toggle_form: (id) ->
    $("#js-comment-form-#{id}").toggle()

  initialize: ->
    $('body').on 'click', '.js-add-comment-link', ->
      id = $(this).data().id
      App.Comments.toggle_form(id)
      false

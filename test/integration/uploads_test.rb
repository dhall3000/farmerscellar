require 'integration_helper'

class UploadsTest < IntegrationHelper

  test "producer should be able to delete a file associated with a posting" do

    #create a photo
    nuke_all_postings
    nuke_all_users
    producer = create_producer
    get_access_for(producer)
    posting = create_posting(producer)

    verify_producer_can_see_post_edit_option(producer, posting)
    get_edit_posting(producer, posting)

    upload_photo_to_posting(producer, posting)

    posting.reload

    assert_equal 1, PostingUpload.count

    #now go back to the posting edit page
    get_edit_posting(producer, posting)
    #nuke the photo from the posting
    delete upload_path(posting.uploads.first), params: {posting_id: posting.id}
    posting.reload
    #verify the photo is gone
    assert_equal 0, posting.uploads.count
    assert_equal 0, Upload.count
    assert_equal 0, PostingUpload.count

    assert_response :redirect
    assert_redirected_to edit_posting_path(posting)
    
  end

  test "producer should be able to upload a file associated with a posting" do

    nuke_all_postings
    nuke_all_users
    producer = create_producer
    get_access_for(producer)
    posting = create_posting(producer)

    verify_producer_can_see_post_edit_option(producer, posting)
    get_edit_posting(producer, posting)

    upload_photo_to_posting(producer, posting)
    
  end

  test "producer should be able to upload a file not associated with a posting" do

    nuke_all_postings
    nuke_all_users
    producer = create_producer
    get_access_for(producer)

    assert_equal 0, Upload.count
    post uploads_path, params: {upload: {name: "filename.jpg"}}
    assert_response :redirect
    assert_redirected_to producer
    follow_redirect!
    assert_template 'users/show'
    assert_equal 1, Upload.count
    
  end
  
end
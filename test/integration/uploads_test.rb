require 'integration_helper'

class UploadsTest < IntegrationHelper

  test "should not be able to upload two files with the same title" do
    
    upload1 = upload_file("awesome.jpg", "mytitle")
    upload2 = upload_file("cool.jpg", "mytitle")

    assert upload1.valid?
    assert_not upload2.valid?

  end

  test "should be able to upload two files without titles" do
    
    upload1 = upload_file("awesome.jpg")
    upload2 = upload_file("cool.jpg")

    assert upload1.valid?
    assert upload2.valid?

  end

  test "photo associated with posting should associate with subsequent postings in the recurrence series" do

    nuke_all_postings
    nuke_all_users
    producer = create_producer
    get_access_for(producer)
    posting = create_posting(producer, price = nil, product = nil, unit = nil, delivery_date = nil, order_cutoff = nil, units_per_case = nil, frequency = 1)
    original_upload_count = posting.uploads.count

    verify_producer_can_see_post_edit_option(producer, posting)
    get_edit_posting(producer, posting)

    #this original posting shoudl now contain zero photos
    assert_equal original_upload_count, posting.uploads.count
    #now upload a photo to this posting
    upload_photo_to_posting(producer, posting)
    #this original posting shoudl now contain one photo
    assert_equal original_upload_count + 1, posting.uploads.count
    #there should only be a single posting in the db right now
    assert_equal 1, Posting.count
    #and this single posting should be open
    assert posting.state?(:OPEN)
    #now go to the order cutoff and process, so this posting should become closed and a new, OPEN'ed posting shoudl be generated
    travel_to posting.order_cutoff
    RakeHelper.do_hourly_tasks
    assert posting.reload.state?(:CLOSED)
    assert_equal 2, Posting.count
    #this new posting should have the photos attached to it from the original posting
    assert_equal original_upload_count + 1, Posting.last.uploads.count

    travel_back
    
  end

  test "producer should be able to delete a file associated with a posting" do

    #create a photo
    nuke_all_postings
    nuke_all_users
    producer = create_producer
    get_access_for(producer)
    posting = create_posting(producer)

    verify_producer_can_see_post_edit_option(producer, posting)
    get_edit_posting(producer, posting)

    original_upload_count = PostingUpload.count
    upload_photo_to_posting(producer, posting)

    posting.reload

    assert_equal original_upload_count + 1, PostingUpload.count

    #now go back to the posting edit page
    get_edit_posting(producer, posting)
    #nuke the photo from the posting
    delete upload_path(posting.uploads.first), params: {posting_id: posting.id}
    posting.reload
    #verify the photo is gone
    assert_equal original_upload_count, posting.uploads.count
    assert_equal original_upload_count, Upload.count
    assert_equal original_upload_count, PostingUpload.count

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
    post uploads_path, params: {upload: {file_name: "filename.jpg"}}
    assert_response :redirect
    assert_redirected_to assigns(:upload)
    follow_redirect!
    assert_template 'uploads/show'
    assert_equal 1, Upload.count
    
  end
  
end
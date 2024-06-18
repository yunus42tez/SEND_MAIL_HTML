*&---------------------------------------------------------------------*
*& Report  ZYT_BT_SEND_MAIL_HTML
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zyt_bt_send_mail_html_git.

TABLES: sflight.

DATA: lt_html_body TYPE bcsy_text,
      lt_text      TYPE bcsy_text.

TYPES: BEGIN OF gty_sflight,
         carrid   TYPE s_carr_id,
         currency TYPE  s_currcode,
         price    TYPE  s_price,
         fldate   TYPE s_date,
         seatsmax TYPE s_seatsmax,
       END OF gty_sflight.

DATA: gt_sflight TYPE TABLE OF gty_sflight,
      gs_sflight TYPE gty_sflight.

DATA: gv_formatted_date TYPE char10,
      gv_date           TYPE s_date.

"Object References
DATA: lo_bcs         TYPE REF TO cl_bcs,
      lo_doc_bcs     TYPE REF TO cl_document_bcs,
      lo_recep       TYPE REF TO if_recipient_bcs,
      lo_sender      TYPE REF TO cl_cam_address_bcs,
      lo_sapuser_bcs TYPE REF TO cl_sapuser_bcs,
      lo_cx_bcx      TYPE REF TO cx_bcs.




"Variables
DATA: lv_bin_filesize TYPE so_obj_len,
      lv_sent_to_all  TYPE os_boolean,
      lv_bin_xstr     TYPE xstring,
      lv_fname        TYPE rs38l_fnam,
      lv_string_text  TYPE string.


DATA: lv_subject_info TYPE so_obj_des.

DATA: lv_who_recep  TYPE adr6-smtp_addr.


SELECT carrid
       currency
       price
       fldate
       seatsmax
  FROM sflight
  INTO TABLE gt_sflight
  UP TO 7 ROWS.


TRY.
*** ----------------& create html table body * ------------------------

    lt_html_body = VALUE #( ( line = '<html>' ) ).

    lt_html_body = VALUE #( BASE lt_html_body
( line = '<head><style>table { font-family: arial, sans-serif; border: 1px solid black; }' ) ).

    lt_html_body = VALUE #( BASE lt_html_body
    ( line = 'table th, td{ border: 1px solid black; text-align: center; padding: 10px; } ' ) ).

    lt_html_body = VALUE #( BASE lt_html_body
    ( line = 'table tr{:nth-child(even) { background-color: #00A170; } </style></head>' ) ).

    lt_html_body = VALUE #( BASE lt_html_body
   ( line = '<body><table>' ) ).

    lt_html_body = VALUE #( BASE lt_html_body
                          ( line = '<tr>' ) ).

    lt_html_body = VALUE #( BASE lt_html_body
                             ( line = '<th style="background-color: #fff;">Hava Limanı Kodu</th>' )
                             ( line = '<th style="background-color: #fff;">Uçuş Tarihi</th>' )
                             ( line = '<th style="background-color: #fff;">Para Birimi</th>' )
                             ( line = '<th style="background-color: #fff;">Ücret</th>' )
                             ( line = '<th style="background-color: #fff;">Maksimum Koltuk Sayısı</th>' ) ).

    lt_html_body = VALUE #( BASE lt_html_body
                            ( line = '</tr>' ) ).

    LOOP AT gt_sflight INTO gs_sflight.
      lt_html_body = VALUE #( BASE lt_html_body
                            ( line = '<tr>' ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = '<td>' ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = gs_sflight-carrid ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = '</td>' ) ).

      lt_html_body = VALUE #( BASE lt_html_body ( line = '<td>' ) ).

      gv_date = gs_sflight-fldate.
      CALL FUNCTION 'CONVERSION_EXIT_PDATE_OUTPUT'
        EXPORTING
          input  = gv_date
        IMPORTING
          output = gv_formatted_date.

      lt_html_body = VALUE #( BASE lt_html_body ( line = gv_formatted_date ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = '</td>' ) ).

      lt_html_body = VALUE #( BASE lt_html_body ( line = '<td>' ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = gs_sflight-currency ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = '</td>' ) ).

      lt_html_body = VALUE #( BASE lt_html_body ( line = '<td>' ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = gs_sflight-price ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = '</td>' ) ).

      lt_html_body = VALUE #( BASE lt_html_body ( line = '<td>' ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = gs_sflight-seatsmax ) ).
      lt_html_body = VALUE #( BASE lt_html_body ( line = '</td>' ) ).

      lt_html_body = VALUE #( BASE lt_html_body
                            ( line = '</tr>' ) ).
    ENDLOOP.

    lt_html_body = VALUE #( BASE lt_html_body ( line = '</table></body>' ) ).

    lt_html_body = VALUE #( BASE lt_html_body ( line = '</html>' ) ).


**** -------- create persistent send request ------------------------

    "First line
    CONCATENATE '<p style="text-align: left; background-color: #fff;">Sayın ilgili,</p>' cl_abap_char_utilities=>newline INTO lv_string_text.
    APPEND lv_string_text TO lt_text.
    CLEAR lv_string_text.
    "Second line
    CONCATENATE '<p style="text-align: left; background-color: #fff;">Uçuş detaylarına ait TEST programıdır.</p>'
    cl_abap_char_utilities=>newline INTO lv_string_text.
    APPEND lv_string_text TO lt_text.
    "Third line
    APPEND LINES OF lt_html_body TO lt_text.
    "Fourth line
    APPEND ' <p style="text-align: left; background-color: #fff;">Best Regards,</p>' TO lt_text.
    "Fifth Line
    APPEND '<p style="text-align: left; background-color: #fff;">Yunus TEZ.</p>' TO lt_text.

    lo_bcs = cl_bcs=>create_persistent(  ). "mail content

***---------------------------------------------------------------------
***-----------------& Create object for Document *------------------------
***---------------------------------------------------------------------
    CONCATENATE 'TEST -'  'Uçuş Bilgileri HTML tablosu' INTO lv_subject_info SEPARATED BY space."subject area

    lo_doc_bcs = cl_document_bcs=>create_document(
    i_type = 'HTM'
    i_text = lt_text[]
    i_subject = lv_subject_info ). "Subject of the Email



***** add document to send request
    CALL METHOD lo_bcs->set_document( lo_doc_bcs ).

***---------------------------------------------------------------------
***------------------------& Set Sender *-------------------------
***---------------------------------------------------------------------
    lo_sender    = cl_cam_address_bcs=>create_internet_address( 'yunus.tez@btc-ag.com.tr' ). " sender is sy-uname when sender is null.
    lo_bcs->set_sender( lo_sender ).

***---------------------------------------------------------------------
***------------------------&Set Recipient *-------------------------
***---------------------------------------------------------------------

*    lo_recep = cl_cam_address_bcs=>create_internet_address(
*                          i_address_string = lv_who_recep ).

    lo_recep = cl_cam_address_bcs=>create_internet_address('yunus.tez@btc-ag.com.tr' ).
    "Add recipient with its respective attributes to send request
    CALL METHOD lo_bcs->add_recipient
      EXPORTING
        i_recipient = lo_recep
        i_express   = 'X'.

    CALL METHOD lo_bcs->set_send_immediately
      EXPORTING
        i_send_immediately = 'X'.

***---------------------------------------------------------------------
***-----------------& Send the email *-----------------------------
***---------------------------------------------------------------------
    CALL METHOD lo_bcs->send(
      EXPORTING
        i_with_error_screen = 'X'
      RECEIVING
        result              = lv_sent_to_all ).

    IF lv_sent_to_all IS NOT INITIAL.
      COMMIT WORK.
      IF sy-subrc EQ 0.
        MESSAGE 'Mail gönderildi' TYPE 'S'.
      ENDIF.
    ENDIF.


***---------------------------------------------------------------------
***-----------------& Exception Handling *------------------------
***---------------------------------------------------------------------
  CATCH cx_bcs INTO lo_cx_bcx.
    "Appropriate Exception Handling
    WRITE: 'Exception:', lo_cx_bcx->error_type.
ENDTRY.

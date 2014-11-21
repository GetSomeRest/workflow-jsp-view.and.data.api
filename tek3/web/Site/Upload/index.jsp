<%--
  User: bouzeig
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<html>
<head>
    <title>Upload</title>
    <link rel="stylesheet" type="text/css" href="/tek3/web/Common/style/generic.css">
   
    <!-- 
    Get Javascript library from https://github.com/Developer-Autodesk/library-javascript-view.and.data.api -->
    <script type="text/javascript" src=../../../web/js/Autodesk.ADN.Toolkit.ViewData.js></script>
    <script language="javascript">
        
        var files = [];
        var viewDataClient;
        var adnViewerMng;

        function info(txt) { document.getElementById('info').innerHTML = txt; }

        function init(){

               // Check for the various File API support.
            if (window.File && window.FileReader && window.FileList && window.Blob) {
              //info("Ready! All required File APIs are supported.");
            } else {
              //info("The File APIs are not fully supported in this browser.");
            }

            // Reset progress indicator on new file selection.
            var progress = document.querySelector('.percent');
            progress.style.width = '0%';
            progress.textContent = '0%';

            // Add Event Listeners
            document.getElementById('files').addEventListener('change', handleFileSelect, false);

            var dropZone = document.getElementById('drop_zone');
            dropZone.addEventListener('dragover', handleDragOver, false);
            dropZone.addEventListener('drop', handleFileDrop, false);

            //document.querySelector('.readBytesButtons').addEventListener('click', readBlob, false);

            document.querySelector('.sendBytesButtons').addEventListener('click', doUploadFile, false);


        }

        function doUploadFile(evt) {

            //sanity checks ...
            var token = '<%=(String) session.getAttribute("token")%>'; // set from the server side on first time invocation.

            if (token === '') {
                console.log('Access Token cannot be empty');
                console.log('Exiting ...');
                return;
            }

             var bucket = 'temp_bucket_for_testing';

             if (bucket === '') {
                info('Bucket name cannot be empty');
                console.log('Bucket name cannot be empty');
                console.log('Exiting ...');
                return;
            }

            
            files = document.getElementById('files').files;

             if (files.length === 0) {
                info("Please select a file!");
                console.log('No file to upload');
                console.log('Exiting ...');
                return;
            }
            //get into business
            viewDataClient = new Autodesk.ADN.Toolkit.ViewData.AdnViewDataClient(
              'https://developer.api.autodesk.com',
              token);
            viewDataClient.getBucketDetailsAsync(
                bucket,
                //onSuccess
                function (bucketResponse) {
                    console.log('Bucket details successful:');
                    console.log(bucketResponse);
                    uploadFiles(bucket, files);
                },
                //onError
                function (error) {
                  info("Bucket doesn't exist.Attempting to create...");
                  
                    console.log("Bucket doesn't exist");
                    console.log("Attempting to create...");
                    createBucket(bucket);
                });




        }

         ///////////////////////////////////////////////////////////////////////////
        // 
        //
        ///////////////////////////////////////////////////////////////////////////
        function createBucket(bucket) {
            var bucketCreationData = {
                bucketKey: bucket,
                servicesAllowed: {},
                policy: 'transient'
            }
            viewDataClient.createBucketAsync(
                bucketCreationData,
                //onSuccess
                function (response) {
                    info('Bucket creation successful');
                    console.log('Bucket creation successful:');
                    console.log(response);
                    uploadFiles(response.key, files);
                },
                //onError
                function (error) {
                    info('Bucket creation failed.');
                    console.log('Bucket creation failed:');
                    console.log(error);
                    console.log('Exiting ...');
                    return;
                });
        }


        ///////////////////////////////////////////////////////////////////////////
        // 
        //
        ///////////////////////////////////////////////////////////////////////////
        function uploadFiles(bucket, files) {
            for (var i = 0; i < files.length; ++i) {
                var file = files[i];
                console.log('Uploading file: ' + file.name + ' ...');
                viewDataClient.uploadFileAsync(
                    file,
                    bucket,
                    file.name,
                    //onSuccess
                    function (response) {
                        info('File upload successful');
                        console.log('File upload successful:');
                        console.log(response);
                        var fileId = response.objects[0].id;
                        var fileName = response.file.name;
                        var registerResponse =
                            viewDataClient.register(fileId);
                        if (registerResponse.Result === "Success" ||
                            registerResponse.Result === "Created") {
                            console.log("Registration result: " +
                                registerResponse.Result);
                          var msg = 'Starting translation: ' +
                                fileId;
                            info(msg);
                            console.log(msg);
                            checkTranslationStatus(
                                fileId,
                                1000 * 60 * 5, //5 mins timeout
                                //onSuccess
                                function (fileId, viewable) {
                                    var msg = "Translation successful: " +
                                        response.file.name;
                                    info(msg);
                                    console.log(msg);
                                    console.log("Viewable: ");
                                    console.log(viewable);

                                   onRegisterSuccess(fileName,viewable);


                                });
                        }
                    },
                    //onError
                    function (error) {
                        info('File upload failed');
                        console.log('File upload failed:');
                        console.log(error);
                    });
            }
        }


        function onRegisterSuccess (fileName,viewable) {
          var  key = fileName;
          var base64URN = viewable.urn;

          document.getElementById('byte_content').innerHTML = "<pre><code>" + "uploaded filename is: '" + key + "'.<BR>" +
                    "urn is: " + base64URN + "</code></pre>";

          var invocation = new XMLHttpRequest();
          invocation.open('POST', '/tek3/web/Site/form/view/list.jsp?name=' + key + '&base64=' + base64URN, false); // do a sync call
          invocation.onreadystatechange = (function(){
            
          })();;  // 
          invocation.send();

        }

        ///////////////////////////////////////////////////////////////////////////
        // 
        //
        ///////////////////////////////////////////////////////////////////////////
        function checkTranslationStatus(fileId, timeout, onSuccess) {
            var startTime = new Date().getTime();
            var timer = setInterval(function () {
                var dt = (new Date().getTime() - startTime) / timeout;
                if (dt >= 1.0) {
                    clearInterval(timer);
                }
                else {
                    viewDataClient.getViewableAsync(
                        fileId,
                        function (response) {
                            console.log(
                                'Translation Progess ' +
                                fileId + ': '
                                + response.progress);
                            if (response.progress === 'complete') {
                                clearInterval(timer);
                                onSuccess(fileId,response);
                            }
                        },
                        function (error) {
                        });
                }
            }, 2000);
        };



        function handleFileSelect(evt) {
            var files = evt.target.files;
            var output = [];
            for (var i = 0, f; f = files[i]; i++) {
              output.push('<li><strong>', escape(f.name), '</strong> (', f.type || 'application/stream', ') - ',
                          f.size, ' bytes, last modified: ',
                          f.lastModifiedDate ? f.lastModifiedDate.toLocaleDateString() : 'n/a',
                          '</li>');
            }
            document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>';
        }

        function handleDragOver(evt) {
            evt.stopPropagation();
            evt.preventDefault();
            evt.dataTransfer.dropEffect = 'copy';
        }

        function handleFileDrop(evt) {
            evt.stopPropagation();
            evt.preventDefault();

            var files = evt.dataTransfer.files; // FileList object.
            document.getElementById('files').files = files;

            // files is a FileList of File objects. List some properties.
            var output = [];
            for (var i = 0, f; f = files[i]; i++) {
              output.push('<li><strong>', escape(f.name), '</strong> (', f.type || 'application/stream', ') - ',
                          f.size, ' bytes, last modified: ',
                          f.lastModifiedDate ? f.lastModifiedDate.toLocaleDateString() : 'n/a',
                          '</li>');
            }
            document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>';
        }


    </script>
</head>


  <body>
  <jsp:include page="../Headers/Top.jsp" />
    <img src="test.none" width="1" height="200">
    <div id="progress_bar"><div class="percent">0%</div></div>
    <h3 id="info"></h3>
      <p></p>
    <div>
        <input  type="file" id="files" name="file" />
        <output id="list"></output>
    </div>

    <div class="drop_zone">
        <div id="drop_zone">Drop files here</div>
    </div>

  <!--
    <span >
        <button class="readBytesButtons">Read File</button>
    </span>-->
      <span >
          <button class="sendBytesButtons">Upload File</button>
      </span>

    <div id="byte_content"></div>
    <script>
      init();
    </script>

  </body>
</html>
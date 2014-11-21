<%@ page import="java.util.Map" %>
<%@ page import="java.util.Iterator" %>
<%--
  User: bouzeig
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<head>
    <link rel="stylesheet" type="text/css" href="/tek3/web/Common/style/generic.css">
</head>

<%
    String token = (String) session.getAttribute("token");
    String urn = request.getParameter("urn");
 %>
    <script>
    var invocation = new XMLHttpRequest();
    function handler() {
      if (invocation.readyState == 4) {
         var payload = invocation.responseText; // TODO no-op
      }
    }
    var token = '<%=token%>'; // set from the server side on first time invocation.
    invocation.open('POST', 'https://developer.api.autodesk.com/utility/v1/settoken', false); // do a sync call
    invocation.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    invocation.onreadystatechange = handler;  // see above
    invocation.withCredentials = true;
    invocation.send("access-token=" + token);   // expected to set the cookie upon server response
    </script>
<%
    if (urn==null || urn.trim().isEmpty()) {
        urn=""; } 
    else {
%>

	<link rel="stylesheet" href="https://developer.api.autodesk.com/viewingservice/v1/viewers/style.css" type="text/css">
    <script src="https://developer.api.autodesk.com/viewingservice/v1/viewers/viewer3D.min.js"></script>
    <script type='text/javascript' src='http://code.jquery.com/jquery-2.1.1.js'></script> 
    <!-- 
    Get Javascript library from https://github.com/Developer-Autodesk/library-javascript-view.and.data.api -->
    <script type="text/javascript" src=../../../web/js/Autodesk.ADN.Toolkit.Viewer.js></script>


      <script>

   
          function initialize() {

            // var token = '<%=token%>'; // set from the server side on first time invocation.
            // var urn = '<%=urn%>';

            var token = Autodesk.Viewing.Private.getParameterByName("accessToken");
            var urn = Autodesk.Viewing.Private.getParameterByName("urn");

            adnViewerMng = new Autodesk.ADN.Toolkit.Viewer.AdnViewerManager(
                                        token,
                                        document.getElementById('viewer1'));
                                    adnViewerMng.loadDocument(urn);
          }


          
      </script>
    <%
      } //jsp else
    %>

<html>
  <head>
    <title>Site Administration</title>
  </head>
  <%if(urn.isEmpty()){%>
    <body>
  <%} else {%>
    <body onload="initialize();" oncontextmenu="return false;">
  <%}%>
  <jsp:include page="../Headers/Top.jsp" />
  <%if(urn.isEmpty()){%>
    <div class="form">
        <% Map viewMap = (Map) session.getAttribute("viewMap");
        if (viewMap!=null && !viewMap.isEmpty()) {
            Iterator it = viewMap.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry pairs = (Map.Entry)it.next();
        %>
        <A HREF="/tek3/web/Site/View/?urn=<%=pairs.getValue()%>&accessToken=<%=token%>">
        <IMG SRC="https://developer.api.autodesk.com/viewingservice/v1/thumbnails/<%=pairs.getValue()%>"></A>
        <!--https://developer.api.autodesk.com/viewingservice/v1/items/urn:adsk.viewing:fs.file:dXJuOmFkc2suczM6ZGVyaXZlZC5maWxlOnRyYW5zbGF0aW9uXzI1X3Rlc3RpbmcvRFdGL01NMzUwMEFzc2VtYmx5LmR3Zg==/output/1/image15.png-->
        <%=pairs.getKey()%><BR>
        <%}}%>
      <!--<form action="index.jsp" autocomplete="false" method="POST">
      URN:  <input type="text" name="urn" size="100"><BR>

      <BR>
      <input type="submit" value="View">

      </form>-->
    </div>
    <%} else {%>
      <div id="viewer1" style="position:absolute; left:390px; top:100px; width:1000px; height:740px; border-color: black; overflow-y:auto; overflow-x:auto; border-style:solid; border-width: 1px;"></div>
    <%}%>
  </body>
</html>
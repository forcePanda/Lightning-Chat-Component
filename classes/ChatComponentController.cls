public class ChatComponentController {
    
    //WrapperClass to handle the GET callout response 
    public class ChannelResponse{
        public string ChannelName;
        public string[] OnlineUserIds;
    }
    
    public ChatComponentController(){
        
    }
    
    //To get the details of current logged in User
    @AuraEnabled
    public static user getCurrentUser(){
       return [select id,firstname,lastName from user where id=:userinfo.getUserId()];
    }
    
    //Callout to the API to push the generic event on the channel 
    @AuraEnabled
    public static integer publishStreamingEvent(string message,string userID){
        
        //Calling helper function to make the API callout
        httpresponse response=makeCallout('POST', message, userID);
        system.debug(response);
        
        return response.getStatusCode();
    }
    
    //Callout to get the list of users subscribed on to the channel
    @AuraEnabled
    public static user[] getOnlineUsers(){
        system.debug('getOnlineUsers called');
        set<id> UserIds=new set<id>();
        httpResponse response=makeCallout('GET', NULL, NULL);
        ChannelResponse ResponseObject=new ChannelResponse();
        system.debug(response.getBody());
        ResponseObject=(ChannelResponse)JSON.deserialize(response.getBody(), ChannelResponse.class);
        
        for(string UserId: ResponseObject.OnlineUserIds ){
            UserIds.add(UserId);
        }
        system.debug('Id List: '+UserIds);
        return [select id,name,firstname,lastName from user where id in :UserIds];        
    }
    
    //Helper function to making the callouts
    private static httpresponse makeCallout(string method, string message, string userId){
        
        string BaseUrl=system.Url.getOrgDomainUrl().toExternalForm();
        http http = new http();
        httprequest request= new httprequest();
        request.setMethod(method);
        request.setEndpoint(BaseUrl+'/services/data/v44.0/sobjects/StreamingChannel/0M66F00000000wsSAA/push');
        request.setHeader('Authorization', 'Bearer ' + getSessionIdFromVfPage());
        request.setHeader('Content-Type','application/json; charset=UTF-8');
		request.setHeader('Accept','application/json');
        if(method=='POST')
			request.setBody('{"pushEvents": [{"payload": "'+message+'`'+userinfo.getUserId()+userinfo.getName()+'","userIds": ["'+userId+'"]}]}');
        system.debug(request.getBody());
        httpresponse response=http.send(request);
        
        return response;
    }
    
    //Extracting session ID from VF page content
    private static string getSessionIdFromVfPage(){
        String startString = 'START';
        String endString = 'END';
        PageReference visualforcePage = Page.SessionIdPage;
        String content;
        try{
            content = visualforcePage.getContent().toString();
        }
        catch(VisualforceException e){
            content=startString+userinfo.getSessionId()+endString;
		}
        Integer s = content.indexOf(startString) + startString.length();
        Integer e = content.indexOf(endString);
        return content.substring(s, e);
    }

}
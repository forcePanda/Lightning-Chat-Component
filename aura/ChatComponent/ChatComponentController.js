({
	/* Calling server side controller to get the current logged in User details */
    doInit :  function(component, event, helper){
        //console.log('Initializing');
        var action=component.get("c.getCurrentUser");
        action.setCallback(this,function(response){
            if(response.getState()==='SUCCESS'){ 
                component.set("v.currentUser",response.getReturnValue());
            }
            else
               console.log(response.getState()); 
        });
        $A.enqueueAction(action);
    },
    
    handleSubscription  : function(component, event, helper) {
        //console.log('handleSubscription Called'); 
        
        //If subscribed, call unsubscribe helper method, else call subscribe helper method
        if(component.get("v.isSubscribed"))
            helper.unsubscribe(component, event, helper);
        else{
            helper.subscribe(component, event, helper);
            
            // Calling helper method to get the users subscribed to that channel
            setTimeout( helper.getOnlineUsers(component, event) , 500);
        }
    },
    
    /* Calling helper method to get the users subscribed to that channel */
    refreshUserlist : function(component, event, helper) {
        helper.getOnlineUsers(component, event);
    },
    
    /* Open the chat window, upon user selection */
    selectChatUser : function(component, event, helper){
        //console.log('selectChatUser called');
        component.set("v.selectedUserId",event.currentTarget.dataset.id);
        component.set("v.selectedUserName",event.currentTarget.dataset.name);
        component.set("v.showChatBox",true);
        component.set("v.isChatActive",true);
    },
    
    /* Calling server side controller to push the generic event with user message
     * and helper method to push the user message on Chat window
     */
    sendMessage :  function(component, event, helper) {
        //console.log('Sending Message');
        var message=component.find("inputMessage").get("v.value");
        
        //calling server side controller to push the generic event with user message
        var action=component.get("c.publishStreamingEvent");
        action.setParams({
            "message" : message,
            "userID"  : component.get("v.selectedUserId")
        });
        action.setCallback(this,function(response){
            if(response.getState()==='SUCCESS'){
                if(response.getReturnValue()===200)
                    component.find("inputMessage").set("v.value",'');
                    helper.handleOutboundMessage(component, event, message); //Calling helper to push message on chat window
            }
            else
               console.log(response.getState()); 
        });
        $A.enqueueAction(action);
    },
    
    /* Closing chat window */
    closeChatWindow : function(component, event, helper){
        component.set("v.showChatBox",false);
    }
})
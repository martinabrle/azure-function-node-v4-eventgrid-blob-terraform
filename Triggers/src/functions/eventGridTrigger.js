const { app } = require('@azure/functions');

app.eventGrid('eventGridTrigger', {
    handler: (event, context) => {
        context.log('Event grid function processed event:', event);
    }
});

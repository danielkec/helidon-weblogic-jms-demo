
package bare;

import java.util.concurrent.SubmissionPublisher;

import javax.enterprise.context.ApplicationScoped;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.sse.Sse;
import javax.ws.rs.sse.SseBroadcaster;
import javax.ws.rs.sse.SseEventSink;

import io.helidon.messaging.connectors.jms.JmsMessage;

import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Outgoing;
import org.glassfish.jersey.media.sse.OutboundEvent;
import org.reactivestreams.FlowAdapters;
import org.reactivestreams.Publisher;

@Path("/frank")
@ApplicationScoped
public class FrankResource {

    SubmissionPublisher<String> emitter = new SubmissionPublisher<>();
    private SseBroadcaster sseBroadcaster;

    @Incoming("from-wls")
    public void receive(JmsMessage<String> msg) {
        if (sseBroadcaster == null) {
            System.out.println("No SSE client subscribed yet: " + msg.getPayload());
            return;
        }
        sseBroadcaster.broadcast(new OutboundEvent.Builder().data(msg.getPayload()).build());
    }

    @Outgoing("to-wls")
    public Publisher<String> registerPublisher() {
        return FlowAdapters.toPublisher(emitter);
    }

    @POST
    @Path("/send/{msg}")
    public void send(@PathParam("msg") String msg) {
        emitter.submit(msg);
    }

    @GET
    @Path("sse")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    public void listenToEvents(@Context SseEventSink eventSink, @Context Sse sse) {
        if (sseBroadcaster == null) {
            sseBroadcaster = sse.newBroadcaster();
        }
        sseBroadcaster.register(eventSink);
    }
}

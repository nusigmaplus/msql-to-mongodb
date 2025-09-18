package org.acme.processors;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.bson.Document;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Named;
import java.util.Map;

@ApplicationScoped
@Named("cdcDeleteProcessor")
public class CdcDeleteProcessor implements Processor {

    @Override
    public void process(Exchange exchange) throws Exception {
        Map<String, Object> payload = exchange.getProperty("cdcPayload", Map.class);
        Map<String, Object> before = (Map<String, Object>) payload.get("before");
        
        // Para DELETE, usamos el ID del registro eliminado
        Integer id = (Integer) before.get("id");
        
        // Crear filtro para MongoDB
        Document filter = new Document("_id", id);
        
        // Guardar el ID para logging
        exchange.setProperty("deletedId", id);
        
        exchange.getIn().setBody(filter);
    }
}
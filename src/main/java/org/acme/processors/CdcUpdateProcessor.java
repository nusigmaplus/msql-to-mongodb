package org.acme.processors;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.bson.Document;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Named;
import java.util.Date;
import java.util.Map;
import java.util.Base64;

@ApplicationScoped
@Named("cdcUpdateProcessor")
public class CdcUpdateProcessor implements Processor {

    @Override
    public void process(Exchange exchange) throws Exception {
        Map<String, Object> payload = exchange.getProperty("cdcPayload", Map.class);
        Map<String, Object> after = (Map<String, Object>) payload.get("after");
        Map<String, Object> before = (Map<String, Object>) payload.get("before");
        Map<String, Object> source = (Map<String, Object>) payload.get("source");
        
        Document document = new Document();
        document.put("_id", after.get("id"));
        document.put("name", after.get("name"));
        document.put("description", after.get("description"));
        
        // Decodificar weight si existe
        if (after.get("weight") != null) {
            String weightBase64 = (String) after.get("weight");
            document.put("weight_base64", weightBase64);
        }
        
        // Metadata
        document.put("operation", "UPDATE");
        document.put("source_timestamp", source.get("ts_ms"));
        document.put("processed_at", new Date());
        document.put("source_lsn", source.get("commit_lsn"));
        
        // Guardar valores anteriores si es necesario
        if (before != null) {
            Document previousValues = new Document();
            previousValues.put("name", before.get("name"));
            previousValues.put("description", before.get("description"));
            document.put("previous_values", previousValues);
        }
        
        exchange.getIn().setBody(document);
    }
}
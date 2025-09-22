package org.acme.processors;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.bson.Document;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Named;
import java.util.Base64;
import java.util.Date;
import java.util.Map;

@ApplicationScoped
@Named("cdcInsertProcessor")
public class CdcInsertProcessor implements Processor {

    @Override
    public void process(Exchange exchange) throws Exception {
        Map<String, Object> payload = exchange.getProperty("cdcPayload", Map.class);
        Map<String, Object> after = (Map<String, Object>) payload.get("after");
        Map<String, Object> source = (Map<String, Object>) payload.get("source");
        
        Document document = new Document();
        document.put("_id", after.get("id"));
        document.put("name", after.get("name"));
        document.put("description", after.get("description"));
        
        // Decodificar weight si existe
        if (after.get("weight") != null) {
            String weightBase64 = (String) after.get("weight");
            byte[] weightBytes = Base64.getDecoder().decode(weightBase64);
            // Aquí necesitarías decodificar según el formato específico de SQL Server decimal
            // Por simplicidad, guardamos el valor base64
            document.put("weight_base64", weightBase64);
        }
        
        // Metadata
        document.put("operation", "INSERT");
        document.put("source_timestamp", source.get("ts_ms"));
        document.put("processed_at", new Date());
        document.put("source_lsn", source.get("commit_lsn"));
        document.put("source_db", source.get("db"));
        document.put("source_schema", source.get("schema"));
        document.put("source_table", source.get("table"));
        
        exchange.getIn().setBody(document);
    }
}
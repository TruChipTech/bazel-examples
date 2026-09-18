package com.example.events;

import samples.event.EventOuterClass.Event;
import samples.common.Common.Severity;

/** Proves the Java bindings generated from the SAME .proto file work. */
public class ReadEvent {
  public static void main(String[] args) throws Exception {
    Event event =
        Event.newBuilder()
            .setId("evt-002")
            .setMessage("built from java")
            .setSeverity(Severity.SEVERITY_INFO)
            .addTags("java")
            .build();

    byte[] wire = event.toByteArray();
    Event parsed = Event.parseFrom(wire);

    System.out.println("id       : " + parsed.getId());
    System.out.println("message  : " + parsed.getMessage());
    System.out.println("severity : " + parsed.getSeverity());
    System.out.println("wire size: " + wire.length + " bytes");
  }
}

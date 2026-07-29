# JPA entities with JUnit test cases

This bundle generates Java entities for JPA API (Jakarta) with Hibernate implementation plus JUnit tests for CRUD operations.

Generated files:

 - in "**project-root**"  
   - **pom.xml** with JPA dependencies
  
   
 - in "**src/main**"

   - in "**src/main/java/{package}/entities**"  
     - **{entity-name}.java** : JPA entity (with JPA annotations)  
     - **{entity-name}Id.java** : JPA composite primary key (if any)  
   
   - in "**src/main/resources/META-INF**"  
     - **persistence.xml** : a JPA configuration file example
   
 - in "**src/test**"
   - in "**src/test/java/{package}/entities**"  
     - **AbstractJpaTest.java** : abstract class for all JUnit tests
     - **{entity-name}Test.java** : JPA JUnit test case
 
   - in "**src/test/resources/META-INF**"  
     - **persistence.xml** : the JPA configuration file for test cases with H2 database

    
 
   
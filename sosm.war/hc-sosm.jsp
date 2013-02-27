<%@ page pageEncoding="euc-kr"
%><%@ page contentType="text/xml;charset=utf-8"

%><%@ page import="java.sql.*, javax.naming.*"
%><%@ page import="javax.sql.*"
%><%@ page import="java.util.Date, java.text.DateFormat"
%><%@ page import="java.text.SimpleDateFormat"

%><%@ page import="java.util.*, java.util.concurrent.atomic.*"
%><%@ page import="java.lang.management.*"

%><%
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setDateHeader("Expires", 0);
%><%!

public String threadInfo() {
	Map<Thread.State, AtomicInteger> sM
		= new LinkedHashMap<Thread.State, AtomicInteger>();
	sM.put(Thread.State.NEW,           new AtomicInteger(0));
	sM.put(Thread.State.BLOCKED,       new AtomicInteger(0));
	sM.put(Thread.State.RUNNABLE,      new AtomicInteger(0));
	sM.put(Thread.State.TIMED_WAITING, new AtomicInteger(0));
	sM.put(Thread.State.WAITING,       new AtomicInteger(0));
	sM.put(Thread.State.TERMINATED,    new AtomicInteger(0));

	Map<Thread, StackTraceElement[]> dump = Thread.getAllStackTraces();
	for (Map.Entry<Thread, StackTraceElement[]> entry : dump.entrySet()) {
		Thread t = entry.getKey();
		sM.get(t.getState()).incrementAndGet();
	}

	String thrtxt = ""
		+ "<new>" + sM.get(Thread.State.NEW) + "</new>"
		+ "<blocked>" + sM.get(Thread.State.BLOCKED) + "</blocked>"
		+ "<runnable>" + sM.get(Thread.State.RUNNABLE) + "</runnable>"
		+ "<timed-waiting>" + sM.get(Thread.State.TIMED_WAITING) + "</timed-waiting>"
		+ "<waiting>" + sM.get(Thread.State.WAITING) + "</waiting>"
		+ "<terminated>" + sM.get(Thread.State.TERMINATED) + "</terminated>"
		+ "";

	return thrtxt;
}

public String memoryInfo() {
	Map<String,Long> map = new HashMap();
	StringBuffer memtxt = new StringBuffer();

	MemoryMXBean mem = ManagementFactory.getMemoryMXBean();
	MemoryUsage hM  = mem.getHeapMemoryUsage();
	MemoryUsage nhM = mem.getNonHeapMemoryUsage();

	memtxt.append("<heap unit=\"MB\">");
	memtxt.append("<init>" + hM.getInit() /1048576 + "</init>");
	memtxt.append("<used>" + hM.getUsed() /1048576 + "</used>");
	memtxt.append("<committed>" + hM.getCommitted() /1048576 + "</committed>");
	memtxt.append("<max>" + hM.getMax() /1048576 + "</max>");
	memtxt.append("</heap>");

	memtxt.append("<non-heap unit=\"MB\">");
	memtxt.append("<init>" + nhM.getInit() /1048576 + "</init>");
	memtxt.append("<used>" + nhM.getUsed() /1048576 + "</used>");
	memtxt.append("<committed>" + nhM.getCommitted() /1048576 + "</committed>");
	memtxt.append("<max>" + nhM.getMax() /1048576 + "</max>");
	memtxt.append("</non-heap>");

	return memtxt.toString();
}


public String findDSandPrint(String path) throws NamingException {
	String text = "";
	try {
		Context ctx = new InitialContext();
		NamingEnumeration list = ctx.list(path);
		while (list.hasMore()) {
			NameClassPair nc = (NameClassPair) list.next();
			String glue = "/";
			if (path == "java:" || path == "") glue = "";
			String childpath = path + glue + nc.getName();

			if (nc.getClassName().contains("NamingContext")) {
				log("nc ["+path+","+ nc.getName() + "::" + nc.getClassName());
				text += findDSandPrint(childpath);
			} else if (nc.getClassName().contains("DataSource")) {
				log("ds ["+path+","+ nc.getName() + "::" + nc.getClassName());
				text += getDSInfoXml(childpath, nc, ctx);
			} else {
				text += getSimpleInfoXml(childpath, nc);
			}
		}
		ctx.close();
	} catch (Exception e) {
		log("error" + text);
		e.printStackTrace();
	}
	return text;
}

public String getSimpleInfoXml(String path, NameClassPair nc) {
	return "\t\t<simple-resource path=\"" + path
			+ "\" class=\"" + nc.getClassName() + "\" />";
}

public String getDSInfoXml(String path, NameClassPair nc, Context ctx) {
	StringBuffer txt = new StringBuffer();
	Connection conn = null;
	String dbms_name = null;

	try {
		DataSource ds = (DataSource) ctx.lookup(path);
		conn = ds.getConnection();
		txt.append("\t\t<datasource path=\"" + path
				+ "\" class=\"" + nc.getClassName()
				+ "\" alive=\"Y\">");
		txt.append("\t\t\t<alive code=\"1\">alive!</alive>");

		/*
		BasicDataSource bds = (BasicDataSource) ds;
		txt.append("<url>" + bds.getUrl() + "</url>");
		txt.append("<url>" + bds.getDriverClassName() + "</url>");
		txt.append("<url>" + bds.getMaxActive() + "</url>");
		txt.append("<url>" + bds.getNumActive() + "</url>");
		txt.append("<url>" + bds.getMaxIdle() + "</url>");
		txt.append("<url>" + bds.getNumIdle() + "</url>");
		txt.append("<url>" + bds.getPassword() + "</url>");
		txt.append("<url>" + bds.getPassword() + "</url>");
		txt.append("<url>" + bds.getNumIdle() + "</url>");
		*/

		DatabaseMetaData dm = conn.getMetaData();
		dbms_name = dm.getDatabaseProductName();
		txt.append("\t\t\t<product>" + dbms_name + "</product>");
		String tmp = dm.getDatabaseProductVersion();
		txt.append("\t\t\t<version>" + tmp + "</version>");
		tmp = dm.getDriverName() + " v" + dm.getDriverVersion();
		txt.append("\t\t\t<driver>" + tmp + "</driver>");
	} catch (Exception e) {
		txt.append("\t\t<datasource path=\"" + path
				+ "\" class=\"" + nc.getClassName()
				+ "\" alive=\"N\">");
		txt.append("\t\t</datasource>");
		return txt.toString();
	}

	try {
		Statement stmt = conn.createStatement();
		ResultSet rs = null;
		String ret = null;
		String query_date = null;
		String query_version = null;
		String query_database = null;
		if (dbms_name == "Oracle") {
			query_date = "SELECT to_char(sysdate,"
					+ "'YYYY-MM-DD HH24:MI:SS') FROM dual";
			query_version = "SELECT banner FROM sys.v_$version";
			query_database = "SELECT ora_database_name FROM dual";
		} else if (dbms_name == "MySQL") {
			query_date = "SELECT date_format(sysdate(),"
					+ "'%Y-%m-%d %H:%i:%s')";
			query_version = "SELECT version()";
			query_database = "SELECT database()";
		} else {
			throw new RuntimeException("Not supported DBMS: "
					+ dbms_name);
		}

		rs = stmt.executeQuery(query_date);
		rs.next();
		ret = rs.getString(1);
		rs.close();
		txt.append("\t\t<date>" + ret + "</date>");

		rs = stmt.executeQuery(query_version);
		rs.next();
		ret = rs.getString(1);
		rs.close();
		txt.append("\t\t<engine>" + ret + "</engine>");

		rs = stmt.executeQuery(query_database);
		rs.next();
		ret = rs.getString(1);
		rs.close();
		txt.append("\t\t<database>" + ret + "</database>");
		stmt.close();
		conn.close();
	} catch (Exception e) {
		txt.append(e);
	}

	txt.append("\t\t</datasource>");
	return txt.toString();
}

%><?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<service-status version="0.1.0" description="service status message">
	<honcheonui>
		<servicegroup><%= System.getProperty("hcu.servicegroup") %></servicegroup>
		<servicegroup><%= System.getProperty("hcu.name") %></servicegroup>
		<role><%= System.getProperty("hcu.role") %></role>
		<port><%= System.getProperty("hcu.port") %></port>
		<opmode><%= System.getProperty("hcu.opmode") %></opmode>
		<portfolio><%= System.getProperty("hcu.portfolio") %></portfolio>
	</honcheonui>
	<was-status>
		<alive code="1">alive!</alive>
		<date><%
		DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Date was_date = new Date();
		out.print(dateFormat.format(was_date));
		%></date>
		<hostname><%= request.getServerName() %></hostname>
		<jdk-name><%= System.getProperty("java.runtime.name") %></jdk-name>
		<jdk-vendor><%= System.getProperty("java.vendor") %></jdk-vendor>
		<jdk-version><%= System.getProperty("java.runtime.version") %></jdk-version>
		<os-name><%= System.getProperty("os.name") %></os-name>
		<os-arch><%= System.getProperty("os.arch") %></os-arch>
		<memory-info><%= memoryInfo() %></memory-info>
		<thread-info><%= threadInfo() %></thread-info>
	</was-status>
	<resource-status>

	<%
	out.println(findDSandPrint("java:"));
	out.println(findDSandPrint(""));
	%>	</resource-status>
</service-status>
<% /* vim: set ts=4 sw=4: */ %>

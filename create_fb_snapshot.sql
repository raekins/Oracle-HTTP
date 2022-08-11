SET SERVEROUTPUT ON
SET LINESIZE 200

define p_wallet_d = 'file:/home/oracle/dbc/commonstore/wallets/ssl';
define p_wallet_p = 'MyPassword1';

CREATE OR REPLACE PROCEDURE fb_snapshot (
  p_url              IN  VARCHAR2,
  p_token            IN  VARCHAR2 DEFAULT NULL,
  p_filesystem       IN  VARCHAR2 DEFAULT NULL,
  p_wallet_path      IN  VARCHAR2 DEFAULT NULL,
  p_wallet_password  IN  VARCHAR2 DEFAULT NULL
) AS
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
  l_text           VARCHAR2(32767);
  l_name             VARCHAR2(256);
  l_value            VARCHAR2(1024);
  l_xauth_token    VARCHAR2(1024);
  l_path           VARCHAR2(200);
 
BEGIN
  UTL_HTTP.set_wallet('&p_wallet_d','&p_wallet_p');

  -- If using HTTPS, open a wallet containing the trusted root certificate.
  IF p_wallet_path IS NOT NULL AND p_wallet_password IS NOT NULL THEN
    UTL_HTTP.set_wallet('file:' || p_wallet_path, p_wallet_password);
  END IF;

  dbms_output.put_line('Create FlashBlade Session');
  dbms_output.put_line('-----------------------------------------------');

  l_path := p_url || '/api/login';

  -- Make a HTTP request and get the response.
  l_http_request  := UTL_HTTP.begin_request(url => l_path, method => 'POST' );

  UTL_HTTP.set_header(r     => l_http_request, 
                      name  => 'api-token', 
                      value => p_token);

  UTL_HTTP.set_header(r     => l_http_request, 
                      name  => 'User-Agent', 
                      value => 'OracleDB/19c');

  l_http_response := UTL_HTTP.get_response(l_http_request);
  dbms_output.put_line('Response status code: '||l_http_response.status_code);
  
  -- Loop through the response.
  BEGIN
    LOOP
      UTL_HTTP.read_text(l_http_response, l_text, 32766);
      dbms_output.put_line (' Logon: ' || l_text);
    END LOOP;
  EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
      dbms_output.put_line ('>');
  END;
 
  -- Loop through HTTP headers
  FOR i IN 1..UTL_HTTP.GET_HEADER_COUNT(l_http_response) LOOP
    UTL_HTTP.GET_HEADER(l_http_response, i, l_name, l_value);
    -- DBMS_OUTPUT.PUT_LINE(l_name || ': ' || l_value);
    IF l_name = 'x-auth-token' THEN
      l_xauth_token := l_value;
    END IF;
  END LOOP;

  dbms_output.put_line('x-auth-token: '||l_xauth_token);
  --UTL_HTTP.end_response(l_http_response);
  
  dbms_output.put_line('>');
  dbms_output.put_line('Perform FileSystem Snapshot of ' || p_filesystem);
  dbms_output.put_line('-----------------------------------------------');

  l_path := p_url || '/api/1.12/file-system-snapshots?sources=' || p_filesystem || chr(38) || 'send=false';
  dbms_output.put_line('>' || l_path);

  -- Make a HTTP request and get the response.
  l_http_request  := UTL_HTTP.begin_request(url => l_path, method => 'POST' );
 
  UTL_HTTP.set_header(r     => l_http_request,
                      name  => 'User-agent',
                      value => 'OracleDB/19c');

  UTL_HTTP.set_header(r     => l_http_request,
                      name  => 'x-auth-token',
                      value => l_xauth_token);

  l_http_response := UTL_HTTP.get_response(l_http_request);

  dbms_output.put_line('Response status code: '||l_http_response.status_code);

  -- Loop through the response.
  BEGIN
    LOOP
      UTL_HTTP.read_text(l_http_response, l_text, 32766);
      dbms_output.put_line (l_text);
    END LOOP;
  EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
      dbms_output.put_line ('>');
  END;

  dbms_output.put_line('>');
  dbms_output.put_line('List FileSystem Snapshots of ' || p_filesystem);
  dbms_output.put_line('-----------------------------------------------');
  -- List FlashBlade snapshots for given filesystem
 
  l_path := p_url || '/api/1.12/file-system-snapshots?sort=created' || chr(38) || 'names_or_sources=' || p_filesystem;
  dbms_output.put_line('>' || l_path);

  -- Make a HTTP request and get the response.
  l_http_request  := UTL_HTTP.begin_request(url => l_path, method => 'GET' );
  
  UTL_HTTP.set_header(r     => l_http_request,
                      name  => 'User-agent',
                      value => 'OracleDB/19c');

  UTL_HTTP.set_header(r     => l_http_request,
                      name  => 'x-auth-token',
                      value => l_xauth_token);

  l_http_response := UTL_HTTP.get_response(l_http_request);

  dbms_output.put_line('Response status code: '||l_http_response.status_code);

  -- Loop through the response.
  BEGIN
    LOOP
      UTL_HTTP.read_text(l_http_response, l_text, 32766);
      DBMS_OUTPUT.put_line (l_text);
    END LOOP;
    UTL_HTTP.end_response(l_http_response);
  EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
      UTL_HTTP.end_response(l_http_response);
  END;

  
END fb_snapshot;
/  

CREATE OR REPLACE FUNCTION "rec"."ft_tipo_incidente_ime" (	
				p_administrador integer, p_id_usuario integer, p_tabla character varying, p_transaccion character varying)
RETURNS character varying AS
$BODY$

/**************************************************************************
 SISTEMA:		Sistema de Reclamos
 FUNCION: 		rec.ft_tipo_incidente_ime
 DESCRIPCION:   Funcion que gestiona las operaciones basicas (inserciones, modificaciones, eliminaciones de la tabla 'rec.ttipo_incidente'
 AUTOR: 		 (admin)
 FECHA:	        10-08-2016 13:52:38
 COMENTARIOS:	
***************************************************************************
 HISTORIAL DE MODIFICACIONES:

 DESCRIPCION:	
 AUTOR:			
 FECHA:		
***************************************************************************/

DECLARE

	v_nro_requerimiento    	integer;
	v_parametros           	record;
	v_id_requerimiento     	integer;
	v_resp		            varchar;
	v_nombre_funcion        text;
	v_mensaje_error         text;
	v_id_tipo_incidente	integer;
			    
BEGIN

    v_nombre_funcion = 'rec.ft_tipo_incidente_ime';
    v_parametros = pxp.f_get_record(p_tabla);

	/*********************************    
 	#TRANSACCION:  'REC_INC_INS'
 	#DESCRIPCION:	Insercion de registros
 	#AUTOR:		admin	
 	#FECHA:		10-08-2016 13:52:38
	***********************************/

	if(p_transaccion='REC_INC_INS')then
					
        begin
        	--Sentencia de la insercion
        	insert into rec.ttipo_incidente(
			estado_reg,
			nombre_incidente,
			nivel,
			fk_tipo_incidente,
			tiempo_respuesta,
			fecha_reg,
			id_usuario_reg,
			usuario_ai,
			id_usuario_ai,
			fecha_mod,
			id_usuario_mod
          	) values(
			'activo',
			v_parametros.nombre_incidente,
			v_parametros.nivel,
			v_parametros.fk_tipo_incidente,
			v_parametros.tiempo_respuesta,
			now(),
			p_id_usuario,
			v_parametros._nombre_usuario_ai,
			v_parametros._id_usuario_ai,
			null,
			null
							
			
			
			)RETURNING id_tipo_incidente into v_id_tipo_incidente;
			
			--Definicion de la respuesta
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje','incidente almacenado(a) con exito (id_tipo_incidente'||v_id_tipo_incidente||')'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_tipo_incidente',v_id_tipo_incidente::varchar);

            --Devuelve la respuesta
            return v_resp;

		end;

	/*********************************    
 	#TRANSACCION:  'REC_INC_MOD'
 	#DESCRIPCION:	Modificacion de registros
 	#AUTOR:		admin	
 	#FECHA:		10-08-2016 13:52:38
	***********************************/

	elsif(p_transaccion='REC_INC_MOD')then

		begin
			--Sentencia de la modificacion
			update rec.ttipo_incidente set
			nombre_incidente = v_parametros.nombre_incidente,
			nivel = v_parametros.nivel,
			fk_tipo_incidente = v_parametros.fk_tipo_incidente,
			tiempo_respuesta = v_parametros.tiempo_respuesta,
			fecha_mod = now(),
			id_usuario_mod = p_id_usuario,
			id_usuario_ai = v_parametros._id_usuario_ai,
			usuario_ai = v_parametros._nombre_usuario_ai
			where id_tipo_incidente=v_parametros.id_tipo_incidente;
               
			--Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','incidente modificado(a)'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_tipo_incidente',v_parametros.id_tipo_incidente::varchar);
               
            --Devuelve la respuesta
            return v_resp;
            
		end;

	/*********************************    
 	#TRANSACCION:  'REC_INC_ELI'
 	#DESCRIPCION:	Eliminacion de registros
 	#AUTOR:		admin	
 	#FECHA:		10-08-2016 13:52:38
	***********************************/

	elsif(p_transaccion='REC_INC_ELI')then

		begin
			--Sentencia de la eliminacion
			delete from rec.ttipo_incidente
            where id_tipo_incidente=v_parametros.id_tipo_incidente;
               
            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','incidente eliminado(a)'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_tipo_incidente',v_parametros.id_tipo_incidente::varchar);
              
            --Devuelve la respuesta
            return v_resp;

		end;
         
	else
     
    	raise exception 'Transaccion inexistente: %',p_transaccion;

	end if;

EXCEPTION
				
	WHEN OTHERS THEN
		v_resp='';
		v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
		v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
		v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
		raise exception '%',v_resp;
				        
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;
ALTER FUNCTION "rec"."ft_tipo_incidente_ime"(integer, integer, character varying, character varying) OWNER TO postgres;
CREATE OR REPLACE FUNCTION rec.ft_feriados_sel (
  p_administrador integer,
  p_id_usuario integer,
  p_tabla varchar,
  p_transaccion varchar
)
RETURNS varchar AS
$body$
/**************************************************************************
 SISTEMA:		Gestion de Reclamos
 FUNCION: 		rec.ft_feriados_sel
 DESCRIPCION:   Funcion que devuelve conjuntos de registros de las consultas relacionadas con la tabla 'rec.tferiados'
 AUTOR: 		 (breydi.vasquez)
 FECHA:	        09-05-2018 20:44:22
 COMENTARIOS:
***************************************************************************
 HISTORIAL DE MODIFICACIONES:
#ISSUE				FECHA				AUTOR				DESCRIPCION
 #0				09-05-2018 20:44:22								Funcion que devuelve conjuntos de registros de las consultas relacionadas con la tabla 'rec.tferiados'
 #
 ***************************************************************************/

DECLARE

	v_consulta    		varchar;
	v_parametros  		record;
	v_nombre_funcion   	text;
	v_resp				varchar;

BEGIN

	v_nombre_funcion = 'rec.ft_feriados_sel';
    v_parametros = pxp.f_get_record(p_tabla);

	/*********************************
 	#TRANSACCION:  'REC_TFDOS_SEL'
 	#DESCRIPCION:	Consulta de datos
 	#AUTOR:		breydi.vasquez
 	#FECHA:		09-05-2018 20:44:22
	***********************************/

	if(p_transaccion='REC_TFDOS_SEL')then

    	begin
    		--Sentencia de la consulta
			v_consulta:='select
						tfdos.id_feriado,
						tfdos.tipo,
						tfdos.fecha,
						tfdos.id_lugar,
						tfdos.descripcion,
                        lug.nombre as lugar,
						tfdos.estado_reg,
						tfdos.estado,
						tfdos.id_origen,
						tfdos.id_usuario_ai,
						tfdos.id_usuario_reg,
						tfdos.fecha_reg,
						tfdos.usuario_ai,
						tfdos.id_usuario_mod,
						tfdos.fecha_mod,
						usu1.cuenta as usr_reg,
						usu2.cuenta as usr_mod
						from rec.tferiados tfdos
						left join segu.tusuario usu1 on usu1.id_usuario = tfdos.id_usuario_reg
						left join segu.tusuario usu2 on usu2.id_usuario = tfdos.id_usuario_mod
                        left join param.tlugar lug on tfdos.id_lugar = lug.id_lugar
				        where date_part(''year'',tfdos.fecha) = date_part(''year'', current_date) and ';

			--Definicion de la respuesta
			v_consulta:=v_consulta||v_parametros.filtro;
			v_consulta:=v_consulta||' order by ' ||v_parametros.ordenacion|| ' ' || v_parametros.dir_ordenacion || ' limit ' || v_parametros.cantidad || ' offset ' || v_parametros.puntero;

			--Devuelve la respuesta
			return v_consulta;

		end;

	/*********************************
 	#TRANSACCION:  'REC_TFDOS_CONT'
 	#DESCRIPCION:	Conteo de registros
 	#AUTOR:		breydi.vasquez
 	#FECHA:		09-05-2018 20:44:22
	***********************************/

	elsif(p_transaccion='REC_TFDOS_CONT')then

		begin
			--Sentencia de la consulta de conteo de registros
			v_consulta:='select count(id_feriado)
					    from rec.tferiados tfdos
					    left join segu.tusuario usu1 on usu1.id_usuario = tfdos.id_usuario_reg
						left join segu.tusuario usu2 on usu2.id_usuario = tfdos.id_usuario_mod
                        left join param.tlugar lug on tfdos.id_lugar = lug.id_lugar
					    where ';

			--Definicion de la respuesta
			v_consulta:=v_consulta||v_parametros.filtro;

			--Devuelve la respuesta
			return v_consulta;

		end;

	else

		raise exception 'Transaccion inexistente';

	end if;

EXCEPTION

	WHEN OTHERS THEN
			v_resp='';
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
			v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
			v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
			raise exception '%',v_resp;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
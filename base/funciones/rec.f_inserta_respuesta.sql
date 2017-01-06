CREATE OR REPLACE FUNCTION rec.f_inserta_respuesta (
  p_administrador integer,
  p_id_usuario integer,
  p_hstore_respuesta public.hstore
)
RETURNS varchar AS
$body$
DECLARE
    v_nombre_funcion   	text;
    v_resp    			varchar;
    v_mensaje 			varchar;
    v_reclamo			record;

    v_num_tramite		varchar;
    v_id_proceso_wf_rec	integer;
    v_id_estado_wf_rec 	integer;
    v_estado_rec		varchar;
    v_id_reclamo		integer;

    va_id_tipo_estado_res 	integer[];
    va_codigo_estado_res 	varchar[];
    va_disparador_res		varchar[];
    va_regla_res			varchar[];
    va_prioridad_res		integer[];

    v_id_estado_actual		integer;

    v_codigo_tipo_proceso	varchar;
    v_id_proceso_macro		integer;
    v_nro_respuesta			varchar;
    v_id_proceso_wf			integer;
    v_id_estado_wf			integer;
    v_codigo_estado			varchar;

    v_id_respuesta			integer;
    v_codigo				varchar;
    v_num_cite				varchar;

    v_respuesta				record;
    v_gestion				integer;
    v_cont_resp 			integer;

    v_record				record;

BEGIN
	 v_nombre_funcion = 'rec.f_inserta_respuesta';


     /*
    HSTORE  PARAMETERS

    (p_hstore_respuesta->'id_reclamo')::integer

    */

           --obtener datos del proceso de reclamo

           select
            r.nro_tramite,
            r.id_proceso_wf,
            r.id_estado_wf,
           	r.estado,
            r.id_reclamo

           into
            v_num_tramite,
            v_id_proceso_wf_rec,
            v_id_estado_wf_rec,
            v_estado_rec,
            v_id_reclamo
           from rec.treclamo r
           where r.id_reclamo = (p_hstore_respuesta->'id_reclamo')::integer;

           --Datos Respuesta
           --begin
           select res.*
           into v_respuesta
           from rec.trespuesta res
           where res.id_reclamo = (p_hstore_respuesta->'id_reclamo')::integer;
           --end;

		  IF  v_estado_rec = 'pendiente_respuesta'  THEN

                select * into v_reclamo
              	from rec.treclamo r
              	where r.id_reclamo = (p_hstore_respuesta->'id_reclamo')::integer;

                SELECT tp.codigo, tp.id_proceso_macro
                INTO v_codigo_tipo_proceso, v_id_proceso_macro
                FROM wf.ttipo_proceso tp
                WHERE tp.codigo = 'RESP' AND tp.estado_reg = 'activo';

            SELECT count(*)
            INTO v_cont_resp
            FROM rec.trespuesta
            WHERE id_reclamo = (p_hstore_respuesta->'id_reclamo')::integer;

            IF (v_cont_resp < 2) THEN

              IF (v_cont_resp=1 and v_respuesta.tipo_respuesta = 'respuesta_final') THEN
              	RAISE EXCEPTION 'NO ES POSIBLE REGISTRAR NUEVA RESPUESTA EL RECLAMO YA CUENTA CON UN RESPUESTA...';
              ELSIF (v_respuesta.tipo_respuesta = 'respuesta_parcial' OR v_cont_resp=0)THEN
              	IF (p_hstore_respuesta->'tipo_respuesta'='respuesta_final' OR v_cont_resp=0)THEN
                  IF (v_respuesta.estado='respuesta_enviada' OR v_cont_resp=0)THEN
                    --OBTENEMOS GESTION
                    --begin
                    select g.gestion
                    into v_gestion
                    from param.tgestion g
                    where g.id_gestion = v_reclamo.id_gestion;
                    --end
                    --codigo de numero de Respuesta
                    --begin
                    v_codigo = (v_codigo_tipo_proceso||'-'||lpad((v_cont_resp+1)::varchar,2,'0')||'-['||v_reclamo.nro_tramite||']');

                    SELECT tf.id_funcionario INTO v_record
                    FROM segu.tusuario tu
                    INNER JOIN orga.tfuncionario tf on tf.id_persona = tu.id_persona
                    INNER JOIN orga.vfuncionario_cargo_lugar vfcl on vfcl.id_funcionario = tf.id_funcionario
                    INNER JOIN rec.treclamo tr on tr.id_usuario_reg = tu.id_usuario
                    WHERE tu.id_usuario = p_id_usuario ;

                    SELECT
                                 ps_id_proceso_wf,
                                 ps_id_estado_wf,
                                 ps_codigo_estado,
                                 ps_nro_tramite
                    INTO
                                 v_id_proceso_wf,
                                 v_id_estado_wf,
                                 v_codigo_estado,
                                 v_nro_respuesta
                   	FROM wf.f_registra_proceso_disparado_wf(
                                p_id_usuario,
                                (p_hstore_respuesta->'_id_usuario_ai')::integer,
                                (p_hstore_respuesta->'_nombre_usuario_ai')::varchar,
                                v_reclamo.id_estado_wf,
                                v_record.id_funcionario,  --id_funcionario wf
                                null,
                                v_codigo,--'Respuesta'||(p_hstore_respuesta->'nro_cite')::varchar,
                                'RESP',
                                v_codigo);
                  insert into rec.trespuesta(
                    id_reclamo,
                    recomendaciones,
                    nro_cite,
                    respuesta,
                    fecha_respuesta,
                    estado_reg,
                    procedente,
                    fecha_notificacion,
                    id_usuario_ai,
                    id_usuario_reg,
                    usuario_ai,
                    fecha_reg,
                    fecha_mod,
                    id_usuario_mod,
                    asunto,
                    tipo_respuesta,
                    id_proceso_wf,
                    id_estado_wf,
                    estado,
                    nro_respuesta
                    ) values(
                    (p_hstore_respuesta->'id_reclamo')::integer,
                    (p_hstore_respuesta->'recomendaciones')::varchar,
                    upper((p_hstore_respuesta->'nro_cite')::varchar),
                    (p_hstore_respuesta->'respuesta')::varchar,
                    (p_hstore_respuesta->'fecha_respuesta')::date,
                    'activo',
                    (p_hstore_respuesta->'procedente')::varchar,
                    (p_hstore_respuesta->'fecha_notificacion')::date,
                    (p_hstore_respuesta->'_id_usuario_ai')::integer,
                    p_id_usuario,
                    (p_hstore_respuesta->'__nombre_usuario_ai')::integer,
                    now(),
                    null,
                    null,
                    (p_hstore_respuesta->'asunto')::varchar,
                    (p_hstore_respuesta->'tipo_respuesta')::varchar,
                    v_id_proceso_wf,
                    v_id_estado_wf,
                    v_codigo_estado,
                    v_codigo
                    )RETURNING id_respuesta into v_id_respuesta;
        			--RAISE EXCEPTION 'ERROR';
                    --Definicion de la respuesta
                    v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Respuesta almacenado(a) con exito (id_respuesta'||v_id_respuesta||')');
                    v_resp = pxp.f_agrega_clave(v_resp,'id_respuesta',v_id_respuesta::varchar);
                    --Devuelve la respuesta

                    return v_resp;
                  ELSE
                  	RAISE EXCEPTION 'LA RESPUESTA PARCIAL NO HA SIDO CONCLUIDA...';
                  END IF;
                ELSE
                	RAISE EXCEPTION 'LA RESPUESTA TIENE QUE SER FINAL...';
              	END IF;
              ELSE
              	RAISE EXCEPTION 'YA TIENE UNA RESPUESTA PARCIAL, INCLUYA UNA RESPUESTA FINAL...';
              END IF;
            ELSE
            	RAISE EXCEPTION 'NO ES POSIBLE REGISTRAR NUEVA RESPUESTA EL RECLAMO YA CUENTA CON UN RESPUESTA......';
            END IF;
          ELSE
          		RAISE EXCEPTION 'NO ES POSIBLE REGISTRAR NUEVA RESPUESTA EL RECLAMO YA CUENTA CON UN RESPUESTA......';
          END IF;
                      /*  SELECT
                           ps_id_tipo_estado,
                           ps_codigo_estado,
                           ps_disparador,
                           ps_regla,
                           ps_prioridad
                        into
                          va_id_tipo_estado_res,
                          va_codigo_estado_res,
                          va_disparador_res,
                          va_regla_res,
                          va_prioridad_res

                      FROM wf.f_obtener_estado_wf(v_id_proceso_wf_rec, v_id_estado_wf_rec,NULL,'siguiente');

                      --RAISE EXCEPTION 'va_id_tipo_estado_res: % -- va_codigo_estado_res: % --va_disparador_res: % --va_regla_res: % --va_prioridad_res: %',va_id_tipo_estado_res,va_codigo_estado_res, va_disparador_res, va_regla_res, va_prioridad_res;


                     IF  va_id_tipo_estado_res[2] is not null  THEN

                      raise exception 'El proceso se encuentra mal parametrizado dentro de Work Flow,  el estado pendiente de proceso solo  admite un estado siguiente,  no admitido (%)',va_codigo_estado_res[2];

                    END IF;



                   IF  va_codigo_estado_res[1] != 'proceso'  THEN
                      raise exception 'El proceso se encuentra mal parametrizado dentro de Work Flow, elsiguiente estado para el proceso de compra deberia ser "proceso" y no % ',va_codigo_estado_res[1];
                    END IF;


                    -- registra estado eactual en el WF para rl procesod e compra


                     v_id_estado_actual =  wf.f_registra_estado_wf(va_id_tipo_estado_res[1],
                                                                   NULL, --id_funcionario
                                                                   v_id_estado_wf_rec,
                                                                   v_id_proceso_wf_rec,
                                                                   p_id_usuario,
                                                                   (p_hstore_respuesta->'_id_usuario_ai')::integer,
                                                                   (p_hstore_respuesta->'_nombre_usuario_ai')::varchar,
                                                                   NULL);
                END IF;
                     RAISE EXCEPTION 'v_id_estado_actual: % ',v_id_estado_actual;

                    --actualiza el proceso

                    -- actuliaza el stado en la solictud
                    update adq.tproceso_compra  p set
                       id_estado_wf =  v_id_estado_actual,
                       estado = va_codigo_estado_pro[1],
                       id_usuario_mod=p_id_usuario,
                       fecha_mod=now()
                     where id_proceso_compra = (p_hstore_cotizacion->'id_proceso_compra')::integer;

                    --iniciar el proceso WF


                   --registra estado de cotizacion

                     SELECT
                               ps_id_proceso_wf,
                               ps_id_estado_wf,
                               ps_codigo_estado
                         into
                               v_id_proceso_wf,
                               v_id_estado_wf,
                               v_codigo_estado
                      FROM wf.f_registra_proceso_disparado_wf(
                               p_id_usuario,
                               (p_hstore_cotizacion->'_id_usuario_ai')::integer,
                               (p_hstore_cotizacion->'_nombre_usuario_ai')::varchar,
                               v_id_estado_actual,
                               v_id_funcionario_aux,
                               v_id_depto,
                               'Cotización del proveedor: '||v_dec_proveedor::varchar,
                               '',
                               v_num_cotizacion);


           ELSEIF  v_estado_pro = 'proceso' THEN

                 --registra estado de cotizacion

                 SELECT
                           ps_id_proceso_wf,
                           ps_id_estado_wf,
                           ps_codigo_estado
                     into
                           v_id_proceso_wf,
                           v_id_estado_wf,
                           v_codigo_estado
                  FROM wf.f_registra_proceso_disparado_wf(
                           p_id_usuario,
                          (p_hstore_cotizacion->'_id_usuario_ai')::integer,
                          (p_hstore_cotizacion->'_nombre_usuario_ai')::varchar,
                           v_id_estado_wf_pro,
                           v_id_funcionario_aux,
                           v_id_depto,
                          'Cotización del proveedor: '||v_dec_proveedor::varchar,
                          '',
                          v_num_cotizacion
                          );

          ELSE


           		 raise exception 'Estado no reconocido % ', v_estado_pro;

          END IF;


            --predefine tiempod de entrega sie s blanco o nulo
            v_tiempo_entrega = (p_hstore_cotizacion->'tiempo_entrega')::varchar;


            IF  v_dias_plazo_entrega_sol is  NULL  THEN
               v_dias_plazo_entrega_sol = 5;
            END IF;

            IF  v_tiempo_entrega is NULL or v_tiempo_entrega = '' THEN
               v_tiempo_entrega  = v_dias_plazo_entrega_sol||' días a partir del dia siguiente de emitida la presente orden';
             END IF;

            --lugar de entrega

            IF (p_hstore_cotizacion->'lugar_entrega') is not NULL   and   (p_hstore_cotizacion->'lugar_entrega') !='' THEN

              v_lugar_entrega_sol = (p_hstore_cotizacion->'lugar_entrega');

            END IF;

            IF (p_hstore_cotizacion->'fecha_entrega')::date is not NULL  THEN

              v_fecha_inicio_sol = (p_hstore_cotizacion->'lugar_entrega')::date;

            END IF;





            --Recupera datos del funcionario de contacto

            select
              per.nombre_completo1 as desc_funcionario1,
              fun.email_empresa,
              fun.telefono_ofi,
              per.celular1,
              per.celular2
            into
              v_registros_fun
            from orga.tfuncionario fun
            inner join segu.vpersona per on per.id_persona = fun.id_persona
            where fun.id_funcionario = v_id_funcionario_sol;


            IF  v_registros_fun.celular2 != '' and v_registros_fun.celular2 is NULL THEN
                v_telefono = COALESCE(v_registros_fun.telefono_ofi||', ','')|| COALESCE(v_registros_fun.celular2,'');
            ELSE
                v_telefono = COALESCE(v_registros_fun.telefono_ofi||', ','')|| COALESCE(v_registros_fun.celular1,'');
            END IF;


            --defni si requiere contrato segun RPC

            if  lower(v_instruc_rpc) = 'iniciar contrato' then
               v_requiere_contrato = 'si';
            else
               v_requiere_contrato = 'no';
            end if;


        	--Sentencia de la insercion
        	insert into adq.tcotizacion(
			estado_reg,
			estado,
			lugar_entrega,
			tipo_entrega,
			fecha_coti,

			id_proveedor,
			--porc_anticipo,
			--precio_total,
			fecha_entrega,
			id_moneda,
			id_proceso_compra,
			fecha_venc,
			obs,
			fecha_adju,
			nro_contrato,
			--porc_retgar,
			fecha_reg,
			id_usuario_reg,
			fecha_mod,
			id_usuario_mod,
            id_estado_wf,
            id_proceso_wf,
            tipo_cambio_conv,
            num_tramite,
            tiempo_entrega,
            id_usuario_ai,
            usuario_ai,
            funcionario_contacto,
            telefono_contacto,
            correo_contacto,
            prellenar_oferta,
            forma_pago,
            requiere_contrato
          	) values(
			'activo',
			v_codigo_estado,
			COALESCE(v_lugar_entrega_sol,'Almacen de Oficina Central'),
			(p_hstore_cotizacion->'tipo_entrega')::varchar,
			(p_hstore_cotizacion->'fecha_coti')::date,

			(p_hstore_cotizacion->'id_proveedor')::integer,
			--v_parametros.porc_anticipo,
			--v_parametros.precio_total,
			v_fecha_inicio_sol,
			(p_hstore_cotizacion->'id_moneda')::integer,
			(p_hstore_cotizacion->'id_proceso_compra')::integer,
			(p_hstore_cotizacion->'fecha_venc')::date,
			(p_hstore_cotizacion->'obs')::text,
			(p_hstore_cotizacion->'fecha_adju')::date,
			(p_hstore_cotizacion->'nro_contrato')::varchar,
			--v_parametros.porc_retgar,
			now(),
			p_id_usuario,
			null,
			null,
            v_id_estado_wf,
            v_id_proceso_wf,
            (p_hstore_cotizacion->'tipo_cambio_conv')::numeric,
            v_num_tramite,
            v_tiempo_entrega,
            (p_hstore_cotizacion->'_id_usuario_ai')::integer,
            (p_hstore_cotizacion->'_nombre_usuario_ai')::varchar,
            v_registros_fun.desc_funcionario1::varchar,
            v_telefono::varchar,
            COALESCE(v_registros_fun.email_empresa,'')::varchar,
            COALESCE((p_hstore_cotizacion->'prellenar_oferta')::varchar,'no'),
            COALESCE((p_hstore_cotizacion->'forma_pago')::varchar,''),
            v_requiere_contrato


            )RETURNING id_cotizacion into v_id_cotizacion;




              --  si es la primera cotizacion (el proceso de compra esta en estado pendiente)

             v_sw_precoti = FALSE;

             IF  v_estado_pro = 'pendiente' THEN

                   --  revisar si el proveedor es el mismo proveedor de la solicitud (precotizacion)
                   --  si es el mismo copiar las catidades y montos ofertadas de la solicitud de talle

                   IF v_id_proveedor_precoti = (p_hstore_cotizacion->'id_proveedor')::integer THEN

                      v_sw_precoti = TRUE;

                      --capturamos la url del documento escaneado de la precotizacion en la solicitu....

                      select
                        dwf.id_documento_wf ,
                        dwf.url,
                        dwf.extension
                      into
                         v_id_documento_wf_pc,
                         v_url,
                         v_extension
                      from wf.tdocumento_wf dwf
                      inner join wf.ttipo_documento td on td.id_tipo_documento = dwf.id_tipo_documento and td.codigo = 'precotizacion'
                      where dwf.id_proceso_wf = v_id_proceso_wf_sol;


                      IF v_id_documento_wf_pc is NULL THEN

                         raise exception 'No existe un documento dcodigo=precotizacion para la solicitud de compra';

                      END IF;


                      --capturamos el id  del documento escaneado de COTIZACION
                      select
                         dwf.id_documento_wf
                      into
                         v_id_documento_wf_co
                      from wf.tdocumento_wf dwf
                      inner join wf.ttipo_documento td
                      on td.id_tipo_documento = dwf.id_tipo_documento and td.codigo = 'cotizacion'

                      where dwf.id_proceso_wf = v_id_proceso_wf;


                      IF v_id_documento_wf_co is NULL THEN

                         raise exception 'No existe un documento de codigo=cotizacion para la cotización';

                      END IF;

                      --modificamos el documento escaneado de la cotizacion
                      update wf.tdocumento_wf set
                        url = v_url,
                        chequeado = 'si',
                        extension = v_extension
                      where id_documento_wf = v_id_documento_wf_co;


                   END IF;



             END IF;

          --si se marca la cotizacion para prellenada forma
          IF (p_hstore_cotizacion->'prellenar_oferta')::varchar = 'si'   THEN
              v_sw_precoti = TRUE;
          END IF;


           --recupera tipo de cambio
           v_tipo_cambio_conv = (p_hstore_cotizacion->'tipo_cambio_conv')::numeric;


           FOR v_registros in  SELECT
               sd.id_solicitud_det,
               sd.cantidad,
               sd.precio_unitario
            from adq.tsolicitud_det sd
            where sd.id_solicitud =v_id_solicitud and sd.estado_reg = 'activo' LOOP

                  IF v_sw_precoti THEN
                    v_cant_of = v_registros.cantidad;
                    v_prec_of = v_registros.precio_unitario;

                    --  calcular el precio unitario en moneda base
                    v_precio_unitario_mb_coti= v_registros.precio_unitario*v_tipo_cambio_conv;

                  ELSE

                    v_cant_of = 0;
                    v_prec_of = 0;
                    v_precio_unitario_mb_coti = 0;

                  END IF;



                  INSERT INTO
                    adq.tcotizacion_det
                  (
                    id_usuario_reg,
                    fecha_reg,
                    estado_reg,
                    id_cotizacion,
                    id_solicitud_det,
                    precio_unitario,
                    cantidad_coti,
                    cantidad_adju,
                    precio_unitario_mb,
                    id_usuario_ai,
                    usuario_ai
                   )
                  VALUES (
                    p_id_usuario,
                    now(),
                   'activo',
                    v_id_cotizacion,
                    v_registros.id_solicitud_det,-- :id_solicitud_det,
                    v_prec_of,--:precio_unitario,
                    v_cant_of,--:cantidad_coti,
                    0,   --cantidad_aduj
                    v_precio_unitario_mb_coti,
                    (p_hstore_cotizacion->'_id_usuario_ai')::integer,
                    (p_hstore_cotizacion->'_nombre_usuario_ai')::varchar
                    );

            END LOOP;

            -- inserta documentos en estado borrador si estan configurados
            v_resp_doc =  wf.f_inserta_documento_wf(p_id_usuario, v_id_proceso_wf, v_id_estado_wf);
            -- verificar documentos
            v_resp_doc = wf.f_verifica_documento(p_id_usuario, v_id_estado_wf);


			--Definicion de la respuesta
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Cotizaciones almacenado(a) con exito (id_cotizacion'||v_id_cotizacion||')');
            v_resp = pxp.f_agrega_clave(v_resp,'id_cotizacion',v_id_cotizacion::varchar);

            --Devuelve la respuesta
            return v_resp;*/

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
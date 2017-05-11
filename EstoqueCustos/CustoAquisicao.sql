-- Constantes
declare @FilialC varchar(2) = '';	-- Filial para modo compartilhado das tabelas. (sempre vazio)
declare @MvEstoq varchar(1) = 'S';	-- Apenas operações que movimentam estoque. (S|N)
declare @TpOpera varchar(1) = 'E';	-- Apenas operações de entrada. (E|S)
declare @RecDel  varchar(1) = '';	-- Situação para "EXCLUSÃO" lógica do registro. (vazio|*)
declare @OpFrete varchar(3) = '08';	-- Codigo de operação para movimentos referentes serviços de transporte. (F4_OPEMOV)
declare @OpAquis varchar(3) = '21';	-- Codigo de operação para movimentos referentes a aquisição de mercadorias. (F4_OPEMOV)

/* ETL das tabelas SD1 e SF8 para composição do custo na aquisição do produto. */
select

	D1P.D1_FILIAL,
	D1P.D1_DOC,
	D1P.D1_SERIE,
	D1P.D1_DTDIGIT,
	D1P.D1_CODPROD,
	D1P.D1_QUANT,
	D1P.D1_TOTAL,
	D1P.D1_VALFRE,
	D1P.D1_DESPESA,
	D1P.D1_CSDIFRE,

	isNull( D1F.D1_CSDIFRE, 0 ) as D1_CSDIFRE

from

	dbo.SD1010 as D1

	cross apply (

		select

			sum( isNull( _D1.D1_TOTAL, 0 ) ) as D1_CSDIFRE

		from

			dbo.SD1010 as _D1

				inner join SF8010 as _F8 on (

					_F8.F8_FILIAL	= _D1.D1_FILIAL	and
					_F8.F8_NFDIFRE	= _D1.D1_DOC	and
					_F8.F8_SEDIFRE	= _D1.D1_SERIE	and
					_F8.D_E_L_E_T_	= @RecDel
				)

		where

			_D1.D1_FILIAL	= D1.D1_FILIAL	and
			_D1.D1_CODPROD	= D1.D1_CODPROD	and
			_F8.F8_NFORIG	= D1.D1_DOC		and
			_F8.F8_SERORIG	= D1.D1_SERIE	and
			_D1.D_E_L_E_T_	= @RecDel		and
			_D1.D1_TES		in (

				select

					_F4.F4_CODIGO

				from

					dbo.SF4010 as _F4

				where

					_F4.F4_FILIAL	= @FilialC	and
					_F4.F4_TIPO		= @TpOpera	and
					_F4.F4_OPEMOV	= @OpFrete	and
					_F4.D_E_L_E_T_	= @RecDel
			)

	) as D1F
	
where

	D1.D_E_L_E_T_	= ''	and
	D1.D1_TES		in (

		select

			_F4.F4_CODIGO

		from

			dbo.SF4010 as _F4

		where

			_F4.F4_FILIAL	= @FilialC	and
			_F4.F4_TIPO		= @TpOpera	and
			_F4.F4_ESTOQUE	= @MvEstoq	and
			_F4.F4_OPEMOV	= @OpAquis	and
			_F4.D_E_L_E_T_	= @RecDel
	);

-- Parametros para filtro da consulta (se necessário utilize coringas para a instrução "LIKE").
declare @FilialE varchar(10) = '01';	-- Filial(is) para modo exclusiva(s) das tabelas. (XX_FILIAL)
declare @Produto varchar(20) = '%';		-- Código do produto desejado.
declare @OpMovto varchar(03) = '21';	-- Codigo de operação para o movimento. (F4_OPEMOV)

-- Constantes
declare @FilialC varchar(2) = '';	-- Filial para modo compartilhado das tabelas. (sempre vazio)
declare @MvEstoq varchar(1) = 'S';	-- Apenas operações que movimentam estoque. (S|N)
declare @TpOpera varchar(1) = 'E';	-- Apenas operações de entrada. (E|S)
declare @RecDel  varchar(1) = '';	-- Situação para "EXCLUSÃO" lógica do registro. (vazio|*)

/* Construção de CTE's */
with

	-- Saldo (Qtde.) e custo médio dos produtos em estoque.
	QryEC ( PRODUTO, SALDO, CUSTOME ) as (

		select

			B2.B2_CODPROD,

			sum( B2.B2_QATU ),
			cast( sum( B2.B2_VATU1 ) / isNull( NullIf( sum( B2.B2_QATU ), 0 ), 1 ) as decimal( 12, 4 ))

		from

			dbo.SB2010 as B2

		where

			B2.B2_FILIAL	like @FilialE	and
			B2.D_E_L_E_T_	= @RecDel

		group by ( B2.B2_CODPROD )
	),

	-- Data da última entrada (NF Compra) do produto.
	QryUE ( PRODUTO, DTDIGIT ) as (

		select

			D1.D1_CODPROD,
			max( D1.D1_DTDIGIT )

		from

			dbo.SD1010 as D1

		where

			D1.D1_FILIAL	like FilialE	and
			D1.D_E_L_E_T_	= @RecDel		and
			D1.D1_TES		in (

				select

					F4.F4_CODIGO

				from

					dbo.SF4010 as F4

				where

					F4.F4_FILIAL	= @FilialC	and		-- Verifique o modo de acesso desta tabela e substitua este filtro se necessário.
					F4.F4_TIPO		= @TpOpera	and
					F4.F4_ESTOQUE	= @MvEstoq	and
					F4.F4_OPEMOV	= @OpMovto	and
					F4.D_E_L_E_T_	= @RecDel
			)

		group by ( D1.D1_CODPROD )
	),

	-- Custo de aquisição (NF Compra) do produto.
	QryCE ( PRODUTO, QTDE, CUSTOUE ) as (

		select

			D1.D1_CODPROD,

			sum( D1.D1_QUANT ),
			cast( sum( D1.D1_CUSTO + D1.D1_CSDIFRE ) / isNull( NullIf( sum( D1.D1_QUANT ), 0 ), 1 ) as decimal( 12, 4 ))

		from

			dbo.vwSD1_CustoAquisicao as D1

				inner join QryUE as Q1 on (

					D1.D1_CODPROD	= PRODUTO	and
					D1_DTDIGIT		= DTDIGIT
				)
	
		where

			D1.D1_FILIAL like @FilialE

		group by ( D1.D1_CODPROD )
	)

select

	Q1.PRODUTO,
	B1.B1_DESC as DESCRICAO,
	SALDO,
	CUSTOME,
	CONVERT( smalldatetime, DTDIGIT ) as DTDIGIT,
	QTDE,
	CUSTOUE

from

	SB1010 as B1

		inner join QryEC as Q1 on ( Q1.PRODUTO = B1.PRODUTO )
		inner join QryCE as Q2 on ( Q2.PRODUTO = B1.PRODUTO )
		inner join QryUE as Q3 on ( Q3.PRODUTO = B1.PRODUTO )

where

	B1.B1_FILIAL	like @FilialE	and
	B1.B1_CODPROD	like @Produto	and
	B1.D_E_L_E_T_	= @RecDel

order by ( PRODUTO );

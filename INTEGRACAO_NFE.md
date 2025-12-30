# Integração com API de Notas Fiscais (NF-e/NFC-e)

## 📋 Visão Geral

Este documento explica como integrar o ComprovApp com a API oficial da SEFAZ para buscar notas fiscais eletrônicas (NF-e) emitidas através do CPF do consumidor.

## ⚠️ Importante

Atualmente, o app está usando **dados simulados** para demonstração. Para integrar com a API real da SEFAZ, siga os passos abaixo.

## 🔐 Requisitos para Integração Real

### 1. Certificado Digital

Você precisará de um certificado digital válido (A1 ou A3):
- **Certificado A1**: Arquivo digital (.pfx ou .p12)
- **Certificado A3**: Cartão ou token criptográfico

### 2. Credenciais de Acesso

- Inscrição estadual (IE)
- CNPJ (caso seja empresa)
- Senha do certificado digital

### 3. Ambiente de Homologação

Antes de usar em produção, teste no ambiente de homologação da SEFAZ.

## 🌐 APIs Disponíveis por Estado

A SEFAZ opera de forma descentralizada. Cada estado pode ter sua própria infraestrutura:

### Ambientes de Autorização:

1. **SVRS** (Sefaz Virtual do Rio Grande do Sul)
   - Estados: AC, AL, AP, DF, ES, MS, PB, RJ, RN, RO, RR, SC, SE, TO
   - URL: https://nfe.svrs.rs.gov.br

2. **SVAN** (Sefaz Virtual do Ambiente Nacional)
   - Estados: MA, PA, PI
   - URL: https://www.sefazvirtual.fazenda.gov.br

3. **Estados com SEFAZ Própria**
   - SP: https://nfe.fazenda.sp.gov.br
   - MG: https://nfe.fazenda.mg.gov.br
   - BA: https://nfe.sefaz.ba.gov.br
   - Etc.

## 📡 Webservices Principais

### 1. Consulta NF-e por Destinatário

Permite buscar todas as NF-e onde o CPF aparece como destinatário.

**Endpoint**: `NFeConsultaDest`

**Método**: SOAP (XML)

**Exemplo de Requisição**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <nfeConsultaNFe xmlns="http://www.portalfiscal.inf.br/nfe">
      <nfeCabecMsg>
        <cUF>35</cUF>
        <versaoDados>4.00</versaoDados>
      </nfeCabecMsg>
      <nfeDadosMsg>
        <consSitNFe>
          <tpAmb>1</tpAmb>
          <xServ>CONSULTAR NFE</xServ>
          <CNPJ>00000000000000</CNPJ>
          <CPF>12345678901</CPF>
          <dhIni>2024-01-01T00:00:00-03:00</dhIni>
          <dhFim>2024-12-31T23:59:59-03:00</dhFim>
        </consSitNFe>
      </nfeDadosMsg>
    </nfeConsultaNFe>
  </soap:Body>
</soap:Envelope>
```

### 2. Consulta por Chave de Acesso

**Endpoint**: `NfeConsultaProtocolo`

Permite consultar uma NF-e específica pela chave de 44 dígitos.

## 🔧 Implementação no Flutter

### Pacotes Necessários

```yaml
dependencies:
  http: ^1.2.0
  xml: ^6.5.0
  crypto: ^3.0.3
  pkcs7: ^1.0.0  # Para trabalhar com certificados
```

### Estrutura de Integração

1. **Configurar Certificado Digital**
```dart
import 'dart:io';
import 'package:pkcs7/pkcs7.dart';

class CertificadoConfig {
  final String caminhoArquivo;
  final String senha;

  SecurityContext getSecurityContext() {
    final context = SecurityContext();
    context.useCertificateChain(caminhoArquivo, password: senha);
    context.usePrivateKey(caminhoArquivo, password: senha);
    return context;
  }
}
```

2. **Criar Cliente SOAP**
```dart
class SefazClient {
  final CertificadoConfig certificado;
  final String urlSefaz;

  Future<String> enviarRequisicao(String xmlRequisicao) async {
    final context = certificado.getSecurityContext();
    final httpClient = HttpClient(context: context);

    final request = await httpClient.postUrl(Uri.parse(urlSefaz));
    request.headers.set('Content-Type', 'application/soap+xml; charset=utf-8');
    request.write(xmlRequisicao);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    return responseBody;
  }
}
```

3. **Atualizar NotaFiscalService**
```dart
// No arquivo: lib/services/nota_fiscal_service.dart

Future<List<NotaFiscal>> buscarNotasPorCPF(String cpf, {
  DateTime? dataInicio,
  DateTime? dataFim,
}) async {
  final sefazClient = SefazClient(
    certificado: _certificadoConfig,
    urlSefaz: _getUrlSefaz(estado),
  );

  final xml = _montarXMLConsultaDestinatario(cpf, dataInicio, dataFim);
  final response = await sefazClient.enviarRequisicao(xml);

  return _parseXMLResponse(response);
}
```

## 🔒 Alternativas Mais Simples

### Opção 1: Usar API de Terceiros

Existem serviços que facilitam a consulta de NF-e:

- **Focus NFe**: https://focusnfe.com.br
- **WebMania**: https://webmaniabr.com/nfe/
- **NFe.io**: https://nfe.io

Essas APIs abstraem a complexidade da comunicação com a SEFAZ.

### Opção 2: QR Code da NFC-e

Para Notas Fiscais de Consumidor Eletrônica (NFC-e), você pode:

1. Escanear o QR Code da nota
2. Extrair a chave de acesso do QR Code
3. Fazer consulta pública pela chave

**Vantagem**: Não precisa de certificado digital para consulta pública!

```dart
Future<NotaFiscal?> consultarPorQRCode(String qrCodeData) async {
  // Extrair chave do QR Code
  final chave = extrairChaveDeQRCode(qrCodeData);

  // Fazer consulta pública (não precisa certificado)
  final url = Uri.parse('https://www.nfe.fazenda.gov.br/portal/consultaPublica');
  final response = await http.get(url.replace(queryParameters: {
    'chNFe': chave,
  }));

  return parseConsultaPublica(response.body);
}
```

## 📱 Implementação Recomendada para MVP

Para um MVP (Minimum Viable Product), recomendo:

1. **Fase 1**: Escanear QR Code das notas e fazer consulta pública
2. **Fase 2**: Integrar com API de terceiros (Focus NFe, etc.)
3. **Fase 3**: Implementar integração direta com SEFAZ

### Por que essa ordem?

- **QR Code**: Rápido, simples, sem certificado
- **API Terceiros**: Profissional, sem complexidade técnica
- **SEFAZ Direta**: Maior controle, mas maior complexidade

## 📚 Documentação Oficial

- [Manual de Integração NF-e](http://www.nfe.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=/fYQh7vA19o=)
- [Portal Nacional da NF-e](http://www.nfe.fazenda.gov.br)
- [Schemas XML da NF-e](http://www.nfe.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=BMPFMBoln3w=)

## 🚀 Próximos Passos

1. Decidir qual abordagem usar (QR Code, API terceiros, ou SEFAZ direta)
2. Se usar SEFAZ direta, obter certificado digital
3. Testar em ambiente de homologação
4. Implementar tratamento de erros robusto
5. Adicionar cache local das notas
6. Implementar sincronização em background

## 💡 Dicas

- Sempre teste em homologação primeiro
- Implemente retry logic para chamadas de API
- Armazene as notas localmente (SQLite)
- Considere implementar OCR para capturar dados de notas em papel
- Adicione validação de autenticidade das notas

## ⚡ Status Atual

✅ Modelo de dados criado
✅ Interface de usuário completa
✅ Validação de CPF
⚠️ Dados simulados (aguardando integração real)
⏳ Integração com SEFAZ (pendente)

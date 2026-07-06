---
name: Good first issue
about: Uma tarefa pequena e isolada, ideal para quem está começando a contribuir
title: "[good_first_issue]"
labels: good first issue
assignees: ''

---

### Contexto
<!--
Explique em 2-3 frases ONDE no projeto isso se encaixa e POR QUE é necessário.
Aponte o(s) arquivo(s) ou pasta(s) relevantes (ex: lib/src/export/, lib/src/ui/).
-->
Exemplo:

O comando export atualmente só suporta CSV. Precisamos adicionar suporte a exportação em formato JSON, seguindo o mesmo padrão usado em lib/src/export/csv_exporter.dart.

#### Tarefa
<!--
Descreva o que precisa ser feito, passo a passo se possível.
Evite deixar decisões de arquitetura em aberto — se o contribuidor precisa
decidir "como" fazer algo estrutural, não é mais uma good first issue.
-->

 Passo 1: ...
 Passo 2: ...
 Passo 3: ...

#### Arquivos relevantes
<!-- Link direto para os arquivos/linhas, se souber -->

lib/src/export/csv_exporter.dart (padrão a seguir)
lib/src/export/export.dart (barrel file, precisa registrar o novo exporter aqui)

#### Critério de aceite
<!-- Como saber que está pronto? -->

 Funcionalidade implementada e testada manualmente
 Testes unitários adicionados (se aplicável)
 Documentação/README atualizado (se necessário)
 Segue os padrões de código já estabelecidos no projeto

#### Dificuldade estimada
<!-- Ajuda o contribuidor a calibrar expectativa -->
🟢 Fácil (poucas horas) / 🟡 Médio (um final de semana) / 🔴 Requer mais contexto
Precisa de ajuda?
Comente aqui ou pergunte antes de começar — sem problema nenhum, é pra isso que o label existe.

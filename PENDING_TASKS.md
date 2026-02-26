# XCMKit - Tareas Pendientes

**Última actualización**: 2026-02-25 23:45 UTC

---

## ⏳ Tareas en Progreso

### 1. PolkaVM Plugin Configuration

**Objetivo**: Habilitar compilación y deployment con PolkaVM para Passet Hub testnet

**Progreso**:
- ✅ Implementado WebSocket polyfill en `hardhat.config.ts`
- ✅ Habilitado `@parity/hardhat-polkadot` plugin
- ✅ Configurado `resolc` compiler v0.3.0 con optimizer
- ✅ Habilitado `polkavm: true` en todas las redes (hardhat, localNode, passetHub)

**Pendiente**:
- [ ] Verificar que la compilación con PolkaVM completa exitosamente
- [ ] Probar deployment a red local con PolkaVM
- [ ] Resolver cualquier issue de compatibilidad con resolc
- [ ] Documentar proceso de deployment

**Archivos Modificados**:
- `contracts/hardhat.config.ts` - WebSocket polyfill + configuración PolkaVM
- `contracts/polyfill-setup.js` - Archivo auxiliar de polyfill

**Comando de Prueba**:
```bash
cd contracts
npx hardhat compile  # Debería compilar con resolc + PolkaVM
```

---

## 📋 Tareas Pendientes por Prioridad

### Alta Prioridad (Pre-Hackathon)

#### 2. Deployment a Testnet
**Dependencia**: Requiere PolkaVM plugin funcionando

**Pasos**:
1. Obtener tokens PAS del faucet de Passet Hub testnet
2. Configurar `.env` con PRIVATE_KEY
3. Desplegar XCMBridge: `npx hardhat ignition deploy ./ignition/modules/XCMBridge.ts --network passetHub`
4. Verificar deployment en Blockscout
5. Copiar dirección del contrato desplegado

#### 3. Actualizar Playground con Contrato Desplegado
**Dependencia**: Requiere deployment completado

**Pasos**:
1. Actualizar `playground/src/config.ts` con dirección real del contrato
2. Cambiar `CONTRACT_ADDRESS` de `0x000...` a dirección desplegada
3. Remover o actualizar el banner de "Demo Mode"
4. Probar transferencia real en testnet
5. Documentar proceso de uso

### Media Prioridad (Pre-Hackathon)

#### 4. Mejorar Cobertura de Tests
**Estado Actual**: 33 tests pasando

**Tests Adicionales Sugeridos**:
- Tests de integración con mock del XCM precompile
- Tests de edge cases (amounts extremos, direcciones inválidas)
- Tests de gas optimization
- Tests de eventos emitidos

#### 5. Documentación de Usuario Final
**Archivos a Crear**:
- `docs/USER_GUIDE.md` - Guía de uso del playground
- `docs/DEVELOPER_GUIDE.md` - Guía para integrar XCMKit en otros contratos
- `docs/DEPLOYMENT.md` - Proceso de deployment paso a paso

### Baja Prioridad (Post-Hackathon)

#### 6. Milestone 2 Features
- Implementar `buildProgram()` para secuencias XCM arbitrarias
- Implementar `queryAssets()` para consultas de balance cross-chain
- Integration tests con Chopsticks (fork local)
- Publicar npm package `@xcmkit/contracts`

#### 7. Milestone 3 Features
- Security audit profesional
- Expandir soporte a top 10 parachains
- Implementar token registry
- Crear contratos de referencia (ejemplos de uso)

---

## 🔧 Issues Conocidos

### WebSocket en Entorno Node.js
**Problema**: `@polkadot-api/ws-provider` espera WebSocket en global pero Node.js no lo provee nativamente

**Solución Implementada**: Polyfill con `ws` package en hardhat.config.ts

**Estado**: Necesita verificación que funciona correctamente

### Tamaño de Bytecode
**Advertencia**: PolkaVM tiene límite de 100KB para bytecode de contratos

**Mitigación Actual**:
- Sin dependencias OpenZeppelin (implementación inline de modifiers)
- Optimizer habilitado en resolc
- Código minimalista en XCMBridge

**Monitoreo**: Verificar tamaño después de compilación con resolc

---

## 📊 Estado del Proyecto

### ✅ Completado (100%)
- Core XCMKit library (6 bibliotecas)
- Test suite (33 tests pasando)
- Playground frontend (React + Vite)
- Demo contract XCMBridge
- Documentación básica

### ⏳ En Progreso (75%)
- PolkaVM plugin configuration
- Deployment preparation

### ⏰ Pendiente (0%)
- Testnet deployment
- Playground connection con contrato real
- Documentación de usuario final

---

## 🎯 Próximos Pasos Inmediatos

1. **Verificar compilación PolkaVM**: Ejecutar `npx hardhat compile` y confirmar que no hay errores
2. **Testear deployment local**: Si compilación exitosa, probar deployment en red hardhat
3. **Obtener tokens PAS**: Usar faucet de Passet Hub testnet
4. **Deployment real**: Desplegar a testnet si todo lo anterior funciona
5. **Conectar playground**: Actualizar config y probar transferencia real

---

## 📞 Recursos

- **Faucet Passet Hub**: https://faucet.polkadot.io/passet-hub
- **Blockscout Explorer**: https://testnet-passet-hub-blockscout.polkadot.io/
- **RPC Endpoint**: https://testnet-passet-hub-eth-rpc.polkadot.io
- **GitHub Repository**: https://github.com/carlos-israelj/XCMKit
- **Plugin Docs**: https://github.com/paritytech/hardhat-polkadot

